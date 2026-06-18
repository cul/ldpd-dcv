import { vi, beforeAll, afterEach, afterAll } from 'vitest';
import '@testing-library/jest-dom/vitest';
import { server } from './mock-api';

// mock resizeObserver so that it is available in components using dnd-kit
// This should be fixed in the next dnd-kit-react release
// https://github.com/clauderic/dnd-kit/issues/2060
// https://stackoverflow.com/a/77011294/18827738
const ResizeObserverMock = vi.fn(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));

vi.stubGlobal('ResizeObserver', ResizeObserverMock);

beforeAll(() => {
  server.listen({ onUnhandledRequest: 'warn' });
});

afterEach(() => {
  server.resetHandlers();
});

afterAll(() => {
  server.close();
});
