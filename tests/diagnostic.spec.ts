import { expect, test } from "@playwright/test";
import { randomUUID } from "node:crypto";

const learnerEmail = "student.a@example.invalid";
const learnerPassword = ["Local-only", "GradiPrep", "2026!"].join("-");
const startPath = "/api/v1/learner/diagnostics/ib-myp-g9-cycle1/start";

test.describe("Cycle 1 Diagnostic — Read & View evidence API", () => {
  test("student starts, saves, resumes and submits an unscored Read & View attempt", async ({ page, request }) => {
    const unauthenticatedStart = await request.post(startPath, {
      data: { idempotency_key: randomUUID() },
    });
    expect(unauthenticatedStart.status()).toBe(401);

    let accessToken = "";
    page.on("request", outgoing => {
      if (new URL(outgoing.url()).pathname === "/api/v1/me" && outgoing.method() === "GET") {
        accessToken = outgoing.headers()["authorization"] ?? accessToken;
      }
    });

    await page.goto("/account");
    await page.getByLabel("Email address").fill(learnerEmail);
    await page.getByLabel("Password").fill(learnerPassword);
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByRole("heading", { name: "Synthetic Student A", exact: true })).toBeVisible();
    await expect.poll(() => Boolean(accessToken)).toBe(true);

    const headers = { Authorization: accessToken };
    const startedResponsePromise = page.waitForResponse(response =>
      new URL(response.url()).pathname === startPath && response.request().method() === "POST",
    );
    await page.getByRole("button", { name: "Start / continue Diagnostic" }).click();
    const started = await startedResponsePromise;
    const startedBody = await started.json() as {
      diagnostic: { diagnostic_code: string; version: number };
      attempt: { id: string; status: string; is_replay: boolean };
      section_status: string;
    };
    expect(started.status(), JSON.stringify(startedBody)).toBe(201);
    await expect(page.getByRole("heading", { name: "The Repair Table", exact: true })).toBeVisible();
    await expect(page.getByText("Read & View section only", { exact: true })).toBeVisible();
    expect(startedBody.diagnostic).toMatchObject({ diagnostic_code: "ib-myp-g9-cycle1", version: 1 });
    expect(startedBody.attempt.status).toBe("in_progress");
    expect(startedBody.attempt.is_replay).toBe(false);
    expect(startedBody.section_status).toBe("read_view_only");

    const resumed = await request.post(startPath, {
      headers,
      data: { idempotency_key: randomUUID() },
    });
    const resumedBody = await resumed.json() as { attempt: { id: string; is_replay: boolean } };
    expect(resumed.status()).toBe(200);
    expect(resumedBody.attempt.id).toBe(startedBody.attempt.id);
    expect(resumedBody.attempt.is_replay).toBe(true);

    const invalidResponse = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/RV01",
      { headers, data: { response: { a: "B", b: ["A", "A"] } } },
    );
    expect(invalidResponse.status()).toBe(400);

    const responses: Array<[string, Record<string, unknown>]> = [
      ["RV01", { a: "B", b: ["A", "C"] }],
      ["RV02", { text: "Nia records what was completed and what must wait, showing a balanced view of the afternoon." }],
      ["RV03", { text: "The bright note creates a lively moment and helps show why the small success matters." }],
      ["RV04", { choice: "A" }],
      ["RV05", { choice: "A" }],
      ["RV06", { text: "The claim exaggerates the result because 17 of the 48 objects were not repaired on the day." }],
      ["RV07a", { text: "Nia sees success as honest progress, while the poster counts outcomes and makes unfinished work visible." }],
      ["RV07b", { text: "The story uses a sequence of events, while the poster groups results into clear visual categories." }],
      ["RV08", { order: ["2", "3", "4", "5", "1"], explanation: "The sequence moves from uncertainty to small success and then an honest record of what remains." }],
      ["RV09", { choice: "B", explanation: "The figures list completed and unfinished outcomes, unlike the tagline or invitation." }],
    ];

    for (const [code, response] of responses) {
      const saved = await request.put(
        "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/" + code,
        { headers, data: { response } },
      );
      const savedBody = await saved.json() as { response?: { observation_code: string; revision_number: number }; error?: string };
      expect(saved.status(), code + ": " + JSON.stringify(savedBody)).toBe(200);
      expect(savedBody.response).toMatchObject({ observation_code: code, revision_number: 1 });
    }

    const submitted = await request.post(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/submit",
      { headers, data: {} },
    );
    const submittedBody = await submitted.json() as {
      attempt?: { attempt_id: string; status: string; saved_observations: number; expected_observations: number };
      error?: string;
    };
    expect(submitted.status(), JSON.stringify(submittedBody)).toBe(200);
    expect(submittedBody.attempt).toMatchObject({
      attempt_id: startedBody.attempt.id,
      status: "submitted",
      saved_observations: 10,
      expected_observations: 10,
    });

    const lateEdit = await request.put(
      "/api/v1/learner/diagnostic-attempts/" + startedBody.attempt.id + "/responses/RV02",
      { headers, data: { response: { text: "Submitted evidence cannot be changed." } } },
    );
    expect(lateEdit.status()).toBe(409);
    await expect(lateEdit.json()).resolves.toMatchObject({ error: "diagnostic_attempt_not_editable" });
  });
});
