// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenStaking is Ownable {
    mapping(address => mapping(address => uint256)) public balanceOf;

    constructor() Ownable(msg.sender) {}

    function depositETH() external payable {
        require(msg.value != 0, "Invaild deposit ether amount");
        balanceOf[address(0)][msg.sender] += msg.value;
    }

    function depositERC20(address token, uint256 amount) external {
        require(amount != 0, "Invaild deposit token amount");
        require(token != address(0), "Invaild deposit token address");
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        balanceOf[token][msg.sender] += amount;
    }

    function withdrawETH(uint256 amount) external {
        require(amount <= balanceOf[address(0)][msg.sender], "Not enough ETH to withdraw");
        require(amount != 0, "Invaild withdraw ether amount");
        balanceOf[address(0)][msg.sender] -= amount;
        (bool sent,) = payable(msg.sender).call{value: amount}("");
        require(sent, "withdraw failed");
    }

    function withdrawERC20(address token, uint256 amount) external {
        require(amount <= balanceOf[token][msg.sender], "Not enough Token to withdraw");
        require(amount != 0, "Invaild withdraw token amount");
        require(token != address(0), "Invaild withdraw token address");
        balanceOf[token][msg.sender] -= amount;
        SafeERC20.safeTransferFrom(IERC20(token), address(this), msg.sender, amount);
    }

    function disperse(
        address sender,
        address[] calldata receivers,
        uint256[] calldata amounts,
        address token,
        bool isPercent
    ) external onlyOwner {
        require(sender != address(0), "Invaild sender address");
        require(receivers.length == amounts.length, "Invaild receivers array length");
        uint256 len = receivers.length;
        uint256 balance = balanceOf[token][sender];
        uint256 total;
        uint256 i;
        for (i = 0; i < len;) {
            require(receivers[i] != address(0) && amounts[i] != 0, "Invaild receivers Input");
            total += amounts[i];
            unchecked {
                ++i;
            }
        }
        if (isPercent) {
            require(total <= 100, "Total percent should be below 100%");
            for (i = 0; i < len;) {
                uint256 amount = amounts[i] * balance / 100;
                balanceOf[token][sender] -= amount;
                balanceOf[token][receivers[i]] += amount;
                unchecked {
                    ++i;
                }
            }
        } else {
            require(total <= balance, "Not enough disperse token");
            balanceOf[token][sender] -= total;
            for (i = 0; i < len;) {
                balanceOf[token][receivers[i]] += amounts[i];
                unchecked {
                    ++i;
                }
            }
        }
    }

    function collect(
        address[] calldata senders,
        uint256[] calldata amounts,
        address receiver,
        address token,
        bool isPercent
    ) external onlyOwner {
        require(receiver != address(0), "Invaild receiver address");
        require(senders.length == amounts.length, "Invaild senders array length");
        uint256 len = senders.length;
        uint256 i;
        for (i = 0; i < len;) {
            require(senders[i] != address(0) && amounts[i] != 0, "Invaild senders Input");
            unchecked {
                ++i;
            }
        }
        if (isPercent) {
            for (i = 0; i < len;) {
                require(amounts[i] <= 100, "Each percent should be below 100%");
                uint256 amount = amounts[i] * balanceOf[token][senders[i]] / 100;
                balanceOf[token][senders[i]] -= amount;
                balanceOf[token][receiver] += amount;
                unchecked {
                    ++i;
                }
            }
        } else {
            for (i = 0; i < len;) {
                require(amounts[i] <= balanceOf[token][senders[i]], "Not enough collect token");
                balanceOf[token][senders[i]] -= amounts[i];
                balanceOf[token][receiver] += amounts[i];
                unchecked {
                    ++i;
                }
            }
        }
    }
}
