/** Shared pure helpers, also exercised by the package's tests. */
export const WEB_ORIGIN = "https://lyamfi.lovable.app";

export function safeRoute(candidate) {
  if (typeof candidate !== "string") return null;
  return /^\/(dashboard|bourse|portefeuille|classement|academie|actualites|simulateurs|macroeconomie)([/?].*)?$/.test(candidate)
    ? candidate
    : null;
}

export function appUrl(candidate) {
  const route = safeRoute(candidate);
  return route ? `${WEB_ORIGIN}${route}` : WEB_ORIGIN;
}

export function marketIsOpen(date) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Casablanca",
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(date);
  const value = (type) => parts.find((part) => part.type === type)?.value;
  const weekday = value("weekday");
  if (weekday === "Sat" || weekday === "Sun") return false;
  const minutes = Number(value("hour")) * 60 + Number(value("minute"));
  return minutes >= 570 && minutes < 930;
}
