import { requireNativeModule } from 'expo';

import FintechSecurity, { IdentifierErrorCodes } from '../index';

const mockGetIdentifier = jest.fn();

jest.mock('expo', () => ({
  NativeModule: class {},
  requireNativeModule: jest.fn(() => ({
    getIdentifier: (...args: unknown[]) => mockGetIdentifier(...args),
  })),
}));

describe('module registration', () => {
  it('resolves the native module registered as FintechSecurity', () => {
    expect(requireNativeModule).toHaveBeenCalledWith('FintechSecurity');
  });

  it('exposes getIdentifier from the native module', async () => {
    mockGetIdentifier.mockResolvedValueOnce('9f2f00b0c94e7e65');

    await expect(FintechSecurity.getIdentifier()).resolves.toBe('9f2f00b0c94e7e65');
  });
});

describe('error codes contract', () => {
  it('keeps the rejection codes stable', () => {
    expect(IdentifierErrorCodes.Unavailable).toBe('ERR_IDENTIFIER_UNAVAILABLE');
    expect(IdentifierErrorCodes.StorageAccess).toBe('ERR_IDENTIFIER_STORAGE_ACCESS');
  });
});
