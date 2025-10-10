import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get("wallet_2")!;

const contractName = "unique-coin-token";

describe("UniCoin Token Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  describe("Token Information", () => {
    it("should return correct token name", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-name", [], deployer);
      expect(result).toBeOk("UniCoin");
    });

    it("should return correct token symbol", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-symbol", [], deployer);
      expect(result).toBeOk("UNI");
    });

    it("should return correct decimals", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-decimals", [], deployer);
      expect(result).toBeOk(6);
    });

    it("should return contract owner", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-contract-owner", [], deployer);
      expect(result).toBePrincipal(deployer);
    });
  });

  describe("Initial State", () => {
    it("should have correct initial supply", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-total-supply", [], deployer);
      expect(result).toBeOk(100000000000); // 100,000 tokens with 6 decimals
    });

    it("should have deployer as initial holder", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-balance", [deployer], deployer);
      expect(result).toBeOk(100000000000);
    });

    it("should have minting enabled initially", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "is-minting-enabled", [], deployer);
      expect(result).toBeBool(true);
    });
  });

  describe("Transfer Functionality", () => {
    it("should allow token holder to transfer tokens", () => {
      const transferAmount = 1000000; // 1 token
      const { result } = simnet.callPublicFn(
        contractName,
        "transfer",
        [transferAmount, deployer, wallet1, null],
        deployer
      );
      expect(result).toBeOk(true);

      // Check balances after transfer
      const senderBalance = simnet.callReadOnlyFn(contractName, "get-balance", [deployer], deployer);
      const receiverBalance = simnet.callReadOnlyFn(contractName, "get-balance", [wallet1], deployer);
      
      expect(senderBalance.result).toBeOk(99999000000);
      expect(receiverBalance.result).toBeOk(1000000);
    });

    it("should not allow unauthorized transfers", () => {
      const transferAmount = 1000000;
      const { result } = simnet.callPublicFn(
        contractName,
        "transfer",
        [transferAmount, deployer, wallet2, null],
        wallet1 // wallet1 trying to transfer deployer's tokens
      );
      expect(result).toBeErr(101); // ERR-NOT-TOKEN-OWNER
    });
  });

  describe("Minting Functionality", () => {
    it("should allow contract owner to mint tokens", () => {
      const mintAmount = 1000000; // 1 token
      const { result } = simnet.callPublicFn(
        contractName,
        "mint",
        [mintAmount, wallet1],
        deployer
      );
      expect(result).toBeOk(true);

      // Check if tokens were minted
      const balance = simnet.callReadOnlyFn(contractName, "get-balance", [wallet1], deployer);
      expect(balance.result).toBeOk(2000000); // Previous transfer + mint
    });

    it("should not allow non-owners to mint tokens", () => {
      const mintAmount = 1000000;
      const { result } = simnet.callPublicFn(
        contractName,
        "mint",
        [mintAmount, wallet1],
        wallet1 // non-owner trying to mint
      );
      expect(result).toBeErr(100); // ERR-OWNER-ONLY
    });

    it("should allow authorized minters to mint tokens", () => {
      // First, add wallet1 as authorized minter
      const addMinter = simnet.callPublicFn(
        contractName,
        "add-authorized-minter",
        [wallet1],
        deployer
      );
      expect(addMinter.result).toBeOk(true);

      // Check if wallet1 is now authorized
      const isAuthorized = simnet.callReadOnlyFn(
        contractName,
        "is-authorized-minter",
        [wallet1],
        deployer
      );
      expect(isAuthorized.result).toBeBool(true);

      // Now wallet1 should be able to mint
      const mintAmount = 500000;
      const mintResult = simnet.callPublicFn(
        contractName,
        "mint",
        [mintAmount, wallet2],
        wallet1
      );
      expect(mintResult.result).toBeOk(true);
    });
  });

  describe("Burn Functionality", () => {
    it("should allow token holders to burn their tokens", () => {
      const burnAmount = 500000;
      const { result } = simnet.callPublicFn(
        contractName,
        "burn",
        [burnAmount],
        wallet1
      );
      expect(result).toBeOk(true);

      // Check balance after burn
      const balance = simnet.callReadOnlyFn(contractName, "get-balance", [wallet1], deployer);
      expect(balance.result).toBeOk(1500000); // 2000000 - 500000
    });

    it("should not allow burning zero amount", () => {
      const { result } = simnet.callPublicFn(
        contractName,
        "burn",
        [0],
        wallet1
      );
      expect(result).toBeErr(103); // ERR-INVALID-AMOUNT
    });
  });

  describe("Admin Functions", () => {
    it("should allow owner to toggle minting", () => {
      const { result } = simnet.callPublicFn(
        contractName,
        "toggle-minting",
        [],
        deployer
      );
      expect(result).toBeOk(true);

      // Check if minting is now disabled
      const isEnabled = simnet.callReadOnlyFn(contractName, "is-minting-enabled", [], deployer);
      expect(isEnabled.result).toBeBool(false);

      // Try minting when disabled
      const mintResult = simnet.callPublicFn(
        contractName,
        "mint",
        [1000000, wallet2],
        deployer
      );
      expect(mintResult.result).toBeErr(104); // ERR-MINTING-DISABLED
    });

    it("should allow owner to remove authorized minters", () => {
      // Re-enable minting first
      simnet.callPublicFn(contractName, "toggle-minting", [], deployer);
      
      const { result } = simnet.callPublicFn(
        contractName,
        "remove-authorized-minter",
        [wallet1],
        deployer
      );
      expect(result).toBeOk(true);

      // Check if wallet1 is no longer authorized
      const isAuthorized = simnet.callReadOnlyFn(
        contractName,
        "is-authorized-minter",
        [wallet1],
        deployer
      );
      expect(isAuthorized.result).toBeBool(false);
    });
  });

  describe("Supply Information", () => {
    it("should return correct total minted", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-total-minted", [], deployer);
      expect(result).toBeUint(101500000); // Initial + minted amounts
    });

    it("should return correct remaining supply", () => {
      const { result } = simnet.callReadOnlyFn(contractName, "get-remaining-supply", [], deployer);
      expect(result).toBeUint(999898500000); // TOTAL_SUPPLY - total_minted
    });
  });
});
