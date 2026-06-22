# Provider Matrix — Solana Fiat Onramp/Offramp

Verified against current documentation as of June 2026. This space moves fast; always re-check provider docs before choosing.

## Africa-Focused

| Provider | Solana | Corridors / Currencies | Capabilities | KYC Tier | Settlement | API Style | Docs |
|----------|--------|------------------------|-------------|----------|------------|-----------|------|
| **Yellow Card** | Confirmed | 20 African countries, 50+ fiat (NGN, KES, GHS, ZAR, XAF, XOF, etc.) | Onramp, offramp, custodial wallets, cross-border payouts | Individual (ID/V-selfie) + Business (director checks, proof of address) | Instant USDC credit on ramp; local payout 1-3 business days | REST API + Node/Python/Ruby SDKs, sandbox environment | docs.yellowcard.engineering |
| **Kotani Pay** | Not confirmed (15+ chains incl. Polygon, Celo, Stellar; no Solana found in docs as of June 2026) | Kenya (M-Pesa), Rwanda, Uganda, expanding East Africa | Onramp, offramp, stablecoin-to-mobile money settlement | Individual (ID + selfie) | Near-instant via M-Pesa STK Push | REST API, USSD/SMS for feature phones | documentation.kotanipay.com |
| **Fonbnk** | Confirmed | 19 emerging markets (Africa, LatAm, SEA) | Airtime-to-stablecoin onramp, bank transfer onramp, B2B settlement | Individual (phone number + airtime purchase; no formal KYC for sub-$ thresholds) | <30 second settlement | REST API, widget | fonbnk.com, alchemy.com |
| **Paychant** | Not confirmed (45+ crypto assets, major blockchains; no explicit Solana mention) | Ghana, Kenya, Nigeria, Uganda, Zambia — bank + mobile money (M-Pesa, MTN MoMo, Airtel) | Onramp, offramp, widget + API | Individual KYC/AML | Variable by rail | REST API, embeddable widget | developer.paychant.com |

## LatAm-Focused

| Provider | Solana | Corridors / Currencies | Capabilities | KYC Tier | Settlement | API Style | Docs |
|----------|--------|------------------------|-------------|----------|------------|-----------|------|
| **Bridge.xyz** (Stripe) | Confirmed — SDP orchestration partner | USD, EUR, GBP, BRL, MXN — ACH, FedWire, SEPA, Pix, SPEI | Onramp, offramp, stablecoin issuance (Open Issuance), cards (Stripe Issuing), wallet orchestration | Business (KYB); individual KYC via wallet onboarding flows | Instant USDC on Solana; local payout 1-2 days | REST API, webhook events, white-label | apidocs.bridge.xyz |
| **Beam (beamlfg.io)** | Solana-native | X/Twitter social graph (not a fiat corridor) | Social token transfers, tipping — **not a fiat onramp** | N/A (wallet-based) | Instant on Solana | @beamrobot tag on X | beamlfg.io |

## Global Aggregators

| Provider | Solana | Corridors / Currencies | Capabilities | KYC Tier | Settlement | API Style | Docs |
|----------|--------|------------------------|-------------|----------|------------|-----------|------|
| **Crossmint** | Confirmed — SDP launch partner | 160+ countries, 50+ chains, multiple local payment methods | Onramp, offramp, programmable wallets, stablecoin orchestration, tokenization, compliance (KYC/AML/Travel Rule) | Individual + Business; tiered; MiCA authorized | Varies by payment method; USDC instant on Solana | REST API, SDK (JS/TS), embeddable widget, webhooks | crossmint.com |
| **Onramper** | Confirmed (Solana official ramp list) | 180+ countries, 30+ ramps, 175+ payment methods | Onramp aggregator, offramp (since Sep 2024), smart routing | Delegated to underlying ramp provider | Varies by ramp routed to | Widget, REST API, smart routing engine | onramper.com |
| **Transak** | Confirmed (Solana official ramp list) | 136+ currencies, 45+ chains | Onramp, offramp, NFT checkout; Web/Android/iOS/RN SDKs | Individual (tiered: email → ID → selfie → proof of address) | Card: instant; bank: 1-3 days | Widget, REST API, SDK (Web, Android, iOS, React Native) | docs.transak.com |
| **MoonPay** | Confirmed — SDP launch partner | 250+ partners, cards + bank + Apple/Google Pay | Onramp, offramp, Open Wallet Standard; acquired DFlow (Solana perps) | Individual (email → ID → selfie + liveness) | Card: instant; bank: 1-3 days | Widget, REST API, webhooks | dev.moonpay.com |
| **Ramp Network** | Confirmed (Solana official ramp list) | 110+ tokens, 40+ chains, Pix (Brazil), instant SEPA | Onramp, offramp, swap; widget + REST API v3 | Individual (tiered: email → ID → selfie) | Pix/instant bank: minute-scale; card: instant | Widget, REST API v3 | docs.rampnetwork.com |

## Enterprise Platform

| Provider | Solana | Corridors / Currencies | Capabilities | KYC Tier | Settlement | API Style | Docs |
|----------|--------|------------------------|-------------|----------|------------|-----------|------|
| **Solana Developer Platform** | Native (Solana Foundation) | Delegated to integrated ramp partners (MoonPay, Lightspark, BVNK) + orchestration (Bridge, Crossmint) | Issuance, Payments, Trading API modules; pre-integrated compliance | Handled by ramp/orchestration partner | Via integrated partner | Unified REST API, dashboard | platform.solana.com |

## Deprecation Watch

- **Kotani Pay** and **Paychant** do not confirm Solana support in current docs. If your target corridor is Kenya/Uganda, verify directly before committing.
- **Beam (beamlfg.io)** is a social tipping bot, not a fiat ramp. Included because it's sometimes miscategorized as a LatAm payment provider.

## Selection Heuristics

| Your Need | Best Fit |
|-----------|----------|
| Africa, 10+ currencies, custodial + compliance | Yellow Card |
| LatAm, B2B treasury, multi-rail | Bridge.xyz |
| Global, full stack (wallets + ramp + compliance) | Crossmint |
| Aggregation, compare rates across ramps | Onramper |
| Enterprise, Solana Foundation ecosystem | Solana Developer Platform |
| Airphone-based, no bank account required | Fonbnk |
