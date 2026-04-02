// https://medium.com/@Nelsonalfonso/understanding-custom-errors-in-typescript-a-complete-guide-f47a1df9354c
export class ApiError extends Error {
  status: number | undefined;
  constructor(message: string, status?: number) {
    super(message);
    this.status = status;
    this.name = "ApiError";
  }
}
const genericAuthMessage = "You are not authorized to access this page. If this is an error, please contact a DLC site administrator!";
export class AuthError extends Error {
  authMessage?: string | undefined;
  constructor(authMessage?: string) {
    super(genericAuthMessage);
    this.authMessage = authMessage;
    this.name = "AuthError";
  }
}
