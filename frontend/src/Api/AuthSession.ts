export const AUTH_STORAGE_KEY = "auth.session.v1";

export interface TokenResponseDTO {
  accessToken?: string | null;
  refreshToken?: string | null;
  accessTokenExpires?: string;
  refreshTokenExpires?: string;
}

export interface StoredAuthSession {
  accessToken: string;
  refreshToken: string;
  accessTokenExpires: string;
  refreshTokenExpires: string;
  receivedAt: string;
}

const toTime = (value?: string | null) => {
  if (!value) return Number.NaN;
  return new Date(value).getTime();
};

export const isTokenExpired = (
  expiresAtIso?: string | null,
  skewMs = 30_000,
) => {
  const expiry = toTime(expiresAtIso);
  if (Number.isNaN(expiry)) return true;
  return Date.now() + skewMs >= expiry;
};

export const normalizeTokenSession = (
  tokens?: TokenResponseDTO | null,
): StoredAuthSession | null => {
  if (
    !tokens?.accessToken ||
    !tokens?.refreshToken ||
    !tokens?.accessTokenExpires ||
    !tokens?.refreshTokenExpires
  ) {
    return null;
  }

  return {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    accessTokenExpires: tokens.accessTokenExpires,
    refreshTokenExpires: tokens.refreshTokenExpires,
    receivedAt: new Date().toISOString(),
  };
};

export const persistAuthSession = (tokens?: TokenResponseDTO | null) => {
  const normalized = normalizeTokenSession(tokens);
  if (!normalized) return false;

  localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(normalized));
  return true;
};

export const getStoredAuthSession = (): StoredAuthSession | null => {
  const raw = localStorage.getItem(AUTH_STORAGE_KEY);
  if (!raw) return null;

  try {
    const parsed = JSON.parse(raw) as Partial<StoredAuthSession>;
    if (
      !parsed.accessToken ||
      !parsed.refreshToken ||
      !parsed.accessTokenExpires ||
      !parsed.refreshTokenExpires
    ) {
      return null;
    }

    return {
      accessToken: parsed.accessToken,
      refreshToken: parsed.refreshToken,
      accessTokenExpires: parsed.accessTokenExpires,
      refreshTokenExpires: parsed.refreshTokenExpires,
      receivedAt: parsed.receivedAt || new Date().toISOString(),
    };
  } catch {
    return null;
  }
};

export const clearAuthSession = () => {
  localStorage.removeItem(AUTH_STORAGE_KEY);
};

export const getAccessToken = () => {
  const session = getStoredAuthSession();
  if (!session) return null;
  if (isTokenExpired(session.accessTokenExpires)) return null;
  return session.accessToken;
};

export const getRefreshToken = () => {
  const session = getStoredAuthSession();
  if (!session) return null;
  if (isTokenExpired(session.refreshTokenExpires)) return null;
  return session.refreshToken;
};

export const hasUsableRefreshToken = () => getRefreshToken() !== null;
