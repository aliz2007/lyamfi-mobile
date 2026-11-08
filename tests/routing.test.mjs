import test from "node:test";
import assert from "node:assert/strict";
import { appUrl, safeRoute, marketIsOpen } from "../scripts/lib.mjs";

test("only known Lyamfi routes can be opened natively", () => {
  assert.equal(safeRoute("/bourse/ATW"), "/bourse/ATW");
  assert.equal(safeRoute("/portefeuille?ligue=123"), "/portefeuille?ligue=123");
  assert.equal(safeRoute("https://evil.example"), null);
  assert.equal(safeRoute("/auth?next=https://evil.example"), null);
  assert.equal(appUrl("/academie"), "https://lyamfi.com/academie");
});

test("Casablanca session boundaries and weekends", () => {
  assert.equal(marketIsOpen(new Date("2026-11-09T08:29:00Z")), false);
  assert.equal(marketIsOpen(new Date("2026-11-09T08:30:00Z")), true);
  assert.equal(marketIsOpen(new Date("2026-11-09T14:30:00Z")), false);
  assert.equal(marketIsOpen(new Date("2026-11-08T10:00:00Z")), false);
});
