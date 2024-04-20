pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/Interactions.sol";
import "../../ocean/Ocean.sol";
import "../../adapters/SushiswapV3Adapter.sol";

contract TestSushiswapV3WETHUSDCEPoolAdapter is Test {
    Ocean ocean;
    address wallet = 0x1eED63EfBA5f81D95bfe37d82C8E736b974F477b;
    address secondaryTokenWallet = 0x1eED63EfBA5f81D95bfe37d82C8E736b974F477b;
    SushiswapV3Adapter adapter;
    address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    function setUp() public {
        vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/<API_KEY>"); // Will start on latest block by default
        ocean = new Ocean("");
        adapter = new SushiswapV3Adapter(address(ocean), 0xB7E50106A5bd3Cf21AF210A755F9C8740890A8c9); // sushi: weth - usdc.e pool address
    }

    function testSwap(bool toggle, uint256 amount, uint256 unwrapFee) public {
        unwrapFee = bound(unwrapFee, 2000, type(uint256).max);
        ocean.changeUnwrapFee(unwrapFee);

        address inputAddress;
        address outputAddress;
        address user;

        if (toggle) {
            user = wallet;
            inputAddress = usdc;
            outputAddress = weth;
        } else {
            user = secondaryTokenWallet;
            inputAddress = weth;
            outputAddress = usdc;
        }

        vm.startPrank(user);

        // taking decimals into account
        amount = bound(amount, 1e17, IERC20(inputAddress).balanceOf(user));

        IERC20(inputAddress).approve(address(ocean), amount);

        uint256 prevInputBalance = IERC20(inputAddress).balanceOf(user);
        uint256 prevOutputBalance = IERC20(outputAddress).balanceOf(user);

        Interaction[] memory interactions = new Interaction[](3);

        interactions[0] = Interaction({ interactionTypeAndAddress: _fetchInteractionId(inputAddress, uint256(InteractionType.WrapErc20)), inputToken: 0, outputToken: 0, specifiedAmount: amount, metadata: bytes32(0) });

        interactions[1] = Interaction({
            interactionTypeAndAddress: _fetchInteractionId(address(adapter), uint256(InteractionType.ComputeOutputAmount)),
            inputToken: _calculateOceanId(inputAddress),
            outputToken: _calculateOceanId(outputAddress),
            specifiedAmount: type(uint256).max,
            metadata: bytes32(0)
        });

        interactions[2] = Interaction({ interactionTypeAndAddress: _fetchInteractionId(outputAddress, uint256(InteractionType.UnwrapErc20)), inputToken: 0, outputToken: 0, specifiedAmount: type(uint256).max, metadata: bytes32(0) });

        // erc1155 token id's for balance delta
        uint256[] memory ids = new uint256[](2);
        ids[0] = _calculateOceanId(inputAddress);
        ids[1] = _calculateOceanId(outputAddress);

        ocean.doMultipleInteractions(interactions, ids);

        uint256 newInputBalance = IERC20(inputAddress).balanceOf(user);
        uint256 newOutputBalance = IERC20(outputAddress).balanceOf(user);

        assertLt(newInputBalance, prevInputBalance);
        assertGt(newOutputBalance, prevOutputBalance);

        vm.stopPrank();
    }

    function _calculateOceanId(address tokenAddress) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenAddress, uint256(0))));
    }

    function _fetchInteractionId(address token, uint256 interactionType) internal pure returns (bytes32) {
        uint256 packedValue = uint256(uint160(token));
        packedValue |= interactionType << 248;
        return bytes32(abi.encode(packedValue));
    }
}