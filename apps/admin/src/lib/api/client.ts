import { z } from "zod";
import { ERROR_CODES } from "@/types/enums";

/**
 * Typed API client skeleton for the admin portal.
 *
 * Every response is validated with a zod schema at the boundary (per coding
 * standards §5). Real auth/MFA wiring lands in EPIC-11; for now requests are
 * sent with credentials so the future httpOnly session cookie is included.
 */

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

/** Standard API error envelope (see enums.md · ErrorCode). */
export const apiErrorSchema = z.object({
  code: z.enum(ERROR_CODES),
  message: z.string(),
  details: z.record(z.string(), z.unknown()).optional(),
});
export type ApiError = z.infer<typeof apiErrorSchema>;

export class ApiClientError extends Error {
  readonly status: number;
  readonly body: ApiError | null;

  constructor(status: number, body: ApiError | null, message: string) {
    super(message);
    this.name = "ApiClientError";
    this.status = status;
    this.body = body;
  }
}

export interface RequestOptions extends Omit<RequestInit, "body"> {
  body?: unknown;
}

/**
 * Perform a request against the API and validate the JSON response against the
 * supplied zod schema. Throws {@link ApiClientError} on non-2xx responses.
 */
export async function apiFetch<TSchema extends z.ZodType>(
  path: string,
  schema: TSchema,
  options: RequestOptions = {},
): Promise<z.infer<TSchema>> {
  const { body, headers, ...rest } = options;

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...rest,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const json: unknown = await response.json().catch(() => null as unknown);

  if (!response.ok) {
    const parsed = apiErrorSchema.safeParse(json);
    throw new ApiClientError(
      response.status,
      parsed.success ? parsed.data : null,
      `API request failed: ${response.status} ${path}`,
    );
  }

  return schema.parse(json);
}
