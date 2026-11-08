/** True only when the trusted audit RPC explicitly confirms persistence. */
export function isAuditAcknowledged(data: unknown, error: unknown): boolean {
  return error == null && data === true;
}
