/**
 * Utility function to extract error messages from unknown error types
 * Handles Error instances, string errors, and unknown error types
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message
  }
  if (typeof error === 'string') {
    return error
  }
  return 'Unknown error'
}

