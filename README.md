# GoatBit — Clarity fungible token (Clarinet)

GoatBit (symbol: `GOAT`) is a minimal fungible token implemented in Clarity and managed with Clarinet.
It provides owner-controlled minting, user burns, transfers, and basic metadata helpers.

## Project layout
- `contracts/goatbit.clar` — the token smart contract
- `Clarinet.toml` — Clarinet project manifest (contract is registered under `[contracts.goatbit]`)

## Prerequisites
- Clarinet installed: https://docs.hiro.so/clarity/clarinet

## Quick start
Check the project compiles:

```bash
clarinet check
```

Open the console:
```bash
clarinet console
```

In the console, you can call functions like:

- Become owner (happens automatically on your first owner-only call) and mint:
```lisp
(contract-call? .goatbit mint '<your-principal>' u1000)
```

- Transfer tokens from the console signer (e.g., `deployer`) to someone else:
```lisp
(contract-call? .goatbit transfer '<recipient-principal>' u100)
```

- Burn your own tokens:
```lisp
(contract-call? .goatbit burn u50)
```

- Read balances and supply:
```lisp
(contract-call? .goatbit get-balance '<principal>')
(contract-call? .goatbit get-total-supply)
(contract-call? .goatbit get-name)
(contract-call? .goatbit get-symbol)
(contract-call? .goatbit get-decimals)
(contract-call? .goatbit get-owner)
```

## Ownership model
- The first caller of an owner-only function (e.g., `mint` or `set-owner`) becomes the owner automatically.
- You can later hand over ownership:
```lisp
(contract-call? .goatbit set-owner '<new-owner-principal>)
```

## Errors
- `u100`: unauthorized (only the owner can call)
- `u101`: zero amount not allowed

## Notes
- Decimals are set to `u6`.
- This is a minimal FT. If you need full SIP-010 trait adherence and metadata standards, consider adding the SIP-010 trait and implementing the required interfaces explicitly.
