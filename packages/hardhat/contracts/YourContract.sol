// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//untested smart contract for research purposes only and not for production use

interface IERC20 {
	function transfer(
		address recipient,
		uint256 amount
	) external returns (bool);

	function balanceOf(address account) external view returns (uint256);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
}

contract YourContract {
	mapping(address => uint256) public ethBalances;
	mapping(address => mapping(address => uint256)) public tokenBalances;
	address public owner;

	event Withdrawn(
		address indexed beneficiary,
		uint256 amount,
		address indexed token
	);
	event TokenWithdrawn(
		address indexed beneficiary,
		uint256 amount,
		address indexed token
	);

	constructor(address _owner) {
		owner = _owner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner can call this function");
		_;
	}

	function depositAndSplitETH(
		address[] calldata recipients,
		uint256[] calldata amounts
	) external payable {
		require(
			recipients.length == amounts.length,
			"Recipients and amounts length mismatch"
		);

		uint256 totalAmount;
		for (uint256 i = 0; i < amounts.length; i++) {
			totalAmount += amounts[i];
		}

		require(
			msg.value == totalAmount,
			"Sent value does not match total split amount"
		);

		for (uint256 i = 0; i < recipients.length; i++) {
			ethBalances[recipients[i]] += amounts[i];
		}
	}

	function depositAndSplitToken(
		address token,
		address[] calldata recipients,
		uint256[] calldata amounts
	) external {
		require(
			recipients.length == amounts.length,
			"Recipients and amounts length mismatch"
		);

		IERC20 erc20 = IERC20(token);
		for (uint256 i = 0; i < recipients.length; i++) {
			require(
				erc20.transferFrom(msg.sender, address(this), amounts[i]),
				"Transfer failed"
			);
			tokenBalances[token][recipients[i]] += amounts[i];
		}
	}

	function withdrawETH() external {
		uint256 amount = ethBalances[msg.sender];
		require(amount > 0, "No ETH balance to withdraw");

		ethBalances[msg.sender] = 0;
		payable(msg.sender).transfer(amount);

		emit Withdrawn(msg.sender, amount, address(0));
	}

	function withdrawToken(address token) external {
    uint256 amount = tokenBalances[token][msg.sender];
    require(amount > 0, "No token balance to withdraw");

    tokenBalances[token][msg.sender] = 0;

    require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");

    emit TokenWithdrawn(msg.sender, amount, token);
}

	function ownerWithdrawETH() external onlyOwner {
		payable(owner).transfer(address(this).balance);
	}

	function ownerWithdrawToken(address token) external onlyOwner {
		uint256 amount = IERC20(token).balanceOf(address(this));
		require(IERC20(token).transfer(owner, amount), "Transfer failed");
	}
}
