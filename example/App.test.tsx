import { fireEvent, render, screen } from '@testing-library/react-native';
import FintechSecurity from 'fintech-security';

import App from './App';

jest.mock('fintech-security', () => ({
  __esModule: true,
  default: { getIdentifier: jest.fn() },
}));

const mockGetIdentifier = FintechSecurity.getIdentifier as jest.Mock;

describe('App', () => {
  it('starts idle and does not call the module on mount', async () => {
    await render(<App />);

    expect(screen.getByText('Press the button to fetch it')).toBeTruthy();
    expect(mockGetIdentifier).not.toHaveBeenCalled();
  });

  it('shows the identifier after pressing the button', async () => {
    mockGetIdentifier.mockResolvedValueOnce('9f2f00b0c94e7e65');
    await render(<App />);

    await fireEvent.press(screen.getByText('Get identifier'));

    expect(await screen.findByText('9f2f00b0c94e7e65')).toBeTruthy();
    expect(mockGetIdentifier).toHaveBeenCalledTimes(1);
  });

  it('shows the typed code and message when the module rejects', async () => {
    mockGetIdentifier.mockRejectedValueOnce(
      Object.assign(new Error('No device identifier is available on this device'), {
        code: 'ERR_IDENTIFIER_UNAVAILABLE',
      }),
    );
    await render(<App />);

    await fireEvent.press(screen.getByText('Get identifier'));

    expect(await screen.findByText('ERR_IDENTIFIER_UNAVAILABLE')).toBeTruthy();
    expect(
      screen.getByText('No device identifier is available on this device'),
    ).toBeTruthy();
  });

  it('falls back to UNKNOWN when the rejection carries no code', async () => {
    mockGetIdentifier.mockRejectedValueOnce(new Error('boom'));
    await render(<App />);

    await fireEvent.press(screen.getByText('Get identifier'));

    expect(await screen.findByText('UNKNOWN')).toBeTruthy();
    expect(screen.getByText('boom')).toBeTruthy();
  });
});
