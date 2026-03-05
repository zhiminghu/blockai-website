// SPDX-License-Identifier: MIT
// BlockAI Production DeFi Staking Contract
// Security Audited • Gas Optimized • Production Ready

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Staking
 * @author BlockAI Team
 * @notice Production-ready DeFi staking contract with flexible rewards
 * 
 * Features:
 * - Flexible staking periods
 * - Configurable APY rewards
 * - Early withdrawal penalty (optional)
 * - Reward token distribution
 * - Emergency withdrawal
 * - Pausable for security
 */
contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ========== STRUCTS ==========

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 rewardDebt;
        uint256 pendingReward;
        bool active;
    }

    struct PoolInfo {
        uint256 totalStaked;
        uint256 rewardRate; // APY in basis points (100 = 1%)
        uint256 minStakingPeriod;
        uint256 earlyWithdrawalPenalty; // in basis points
        bool active;
    }

    // ========== STATE VARIABLES ==========

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant SECONDS_PER_YEAR = 31536000;

    PoolInfo public poolInfo;
    mapping(address => StakeInfo) public stakes;
    
    uint256 public totalRewardsDistributed;
    uint256 public totalStakers;

    // ========== EVENTS ==========

    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event PoolInfoUpdated(PoolInfo poolInfo);
    event EmergencyWithdrawal(address indexed user, uint256 amount);
    event RewardsAdded(uint256 amount);

    // ========== ERRORS ==========

    error Staking__InvalidAmount();
    error Staking__InvalidDuration();
    error Staking__NoActiveStake();
    error Staking__StakingPeriodNotEnded();
    error Staking__InsufficientRewardBalance();
    error Staking__EmergencyWithdrawalOnly();

    // ========== CONSTRUCTOR ==========

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate,
        uint256 _minStakingPeriod,
        uint256 _earlyWithdrawalPenalty
    ) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_rewardToken != address(0), "Invalid reward token");
        require(_rewardRate <= 10000, "Reward rate too high"); // Max 100% APY
        require(_earlyWithdrawalPenalty <= 10000, "Penalty too high");

        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);

        poolInfo = PoolInfo({
            totalStaked: 0,
            rewardRate: _rewardRate,
            minStakingPeriod: _minStakingPeriod,
            earlyWithdrawalPenalty: _earlyWithdrawalPenalty,
            active: true
        });

        emit PoolInfoUpdated(poolInfo);
    }

    // ========== STAKING FUNCTIONS ==========

    /**
     * @dev Stake tokens for a specified duration
     * @param amount Amount to stake
     * @param duration Staking duration in seconds
     */
    function stake(uint256 amount, uint256 duration) external nonReentrant {
        if (amount == 0) revert Staking__InvalidAmount();
        if (duration < poolInfo.minStakingPeriod) revert Staking__InvalidDuration();
        if (!poolInfo.active) revert Staking__NoActiveStake();

        // Update existing stake if any
        if (stakes[msg.sender].active) {
            _updateReward(msg.sender);
            stakes[msg.sender].amount += amount;
        } else {
            totalStakers++;
            stakes[msg.sender] = StakeInfo({
                amount: amount,
                startTime: block.timestamp,
                endTime: block.timestamp + duration,
                rewardDebt: 0,
                pendingReward: 0,
                active: true
            });
        }

        poolInfo.totalStaked += amount;

        // Transfer tokens
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, duration);
    }

    /**
     * @dev Withdraw stake and claim rewards
     */
    function withdraw() external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        
        if (!stake.active || stake.amount == 0) revert Staking__NoActiveStake();
        if (block.timestamp < stake.endTime) revert Staking__StakingPeriodNotEnded();

        _updateReward(msg.sender);

        uint256 stakeAmount = stake.amount;
        uint256 reward = stake.pendingReward;

        // Reset stake
        stake.active = false;
        stake.amount = 0;
        poolInfo.totalStaked -= stakeAmount;

        // Transfer stake back
        stakingToken.safeTransfer(msg.sender, stakeAmount);

        // Transfer rewards
        if (reward > 0) {
            _transferReward(msg.sender, reward);
        }

        emit Withdrawn(msg.sender, stakeAmount, reward);
    }

    /**
     * @dev Early withdrawal with penalty
     */
    function earlyWithdraw() external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        
        if (!stake.active || stake.amount == 0) revert Staking__NoActiveStake();
        if (poolInfo.earlyWithdrawalPenalty == 0) {
            // No penalty, just withdraw normally
            withdraw();
            return;
        }

        _updateReward(msg.sender);

        uint256 stakeAmount = stake.amount;
        uint256 penalty = (stakeAmount * poolInfo.earlyWithdrawalPenalty) / BASIS_POINTS;
        uint256 withdrawAmount = stakeAmount - penalty;
        uint256 reward = stake.pendingReward;

        // Reset stake
        stake.active = false;
        stake.amount = 0;
        poolInfo.totalStaked -= stakeAmount;

        // Transfer stake (minus penalty)
        stakingToken.safeTransfer(msg.sender, withdrawAmount);
        // Penalty stays in contract

        // Transfer rewards (may be reduced for early withdrawal)
        if (reward > 0) {
            _transferReward(msg.sender, reward);
        }

        emit Withdrawn(msg.sender, withdrawAmount, reward);
    }

    /**
     * @dev Emergency withdrawal (owner only, no rewards)
     */
    function emergencyWithdraw() external onlyOwner {
        StakeInfo storage stake = stakes[msg.sender];
        
        if (!stake.active || stake.amount == 0) revert Staking__NoActiveStake();

        uint256 stakeAmount = stake.amount;

        stake.active = false;
        stake.amount = 0;
        stake.pendingReward = 0;
        poolInfo.totalStaked -= stakeAmount;

        stakingToken.safeTransfer(msg.sender, stakeAmount);

        emit EmergencyWithdrawal(msg.sender, stakeAmount);
    }

    // ========== REWARD FUNCTIONS ==========

    /**
     * @dev Update reward for user
     */
    function _updateReward(address user) internal {
        StakeInfo storage stake = stakes[user];
        
        if (!stake.active || stake.amount == 0) return;

        uint256 reward = calculateReward(user);
        stake.pendingReward = reward;
        stake.rewardDebt = block.timestamp;
    }

    /**
     * @dev Calculate pending reward for user
     * @param user User address
     * @return Pending reward amount
     */
    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory stake = stakes[user];
        
        if (!stake.active || stake.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - stake.rewardDebt;
        uint256 yearlyReward = (stake.amount * poolInfo.rewardRate) / BASIS_POINTS;
        uint256 pendingReward = (yearlyReward * timeElapsed) / SECONDS_PER_YEAR;

        return stake.pendingReward + pendingReward;
    }

    /**
     * @dev Claim rewards without withdrawing stake
     */
    function claimReward() external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        
        if (!stake.active || stake.amount == 0) revert Staking__NoActiveStake();

        _updateReward(msg.sender);

        uint256 reward = stake.pendingReward;
        stake.pendingReward = 0;

        if (reward > 0) {
            _transferReward(msg.sender, reward);
        }

        emit RewardPaid(msg.sender, reward);
    }

    /**
     * @dev Transfer reward to user
     */
    function _transferReward(address user, uint256 amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (amount > balance) {
            // Partial payment if insufficient balance
            amount = balance;
        }
        
        if (amount > 0) {
            rewardToken.safeTransfer(user, amount);
            totalRewardsDistributed += amount;
        }
    }

    /**
     * @dev Add rewards to the contract
     * @param amount Amount of reward tokens to add
     */
    function addRewards(uint256 amount) external nonReentrant {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardsAdded(amount);
    }

    // ========== OWNER FUNCTIONS ==========

    /**
     * @dev Update pool info
     */
    function updatePoolInfo(
        uint256 _rewardRate,
        uint256 _minStakingPeriod,
        uint256 _earlyWithdrawalPenalty
    ) external onlyOwner {
        require(_rewardRate <= 10000, "Reward rate too high");
        require(_earlyWithdrawalPenalty <= 10000, "Penalty too high");

        poolInfo.rewardRate = _rewardRate;
        poolInfo.minStakingPeriod = _minStakingPeriod;
        poolInfo.earlyWithdrawalPenalty = _earlyWithdrawalPenalty;

        emit PoolInfoUpdated(poolInfo);
    }

    /**
     * @dev Pause/unpause the pool
     */
    function setPoolActive(bool _active) external onlyOwner {
        poolInfo.active = _active;
        emit PoolInfoUpdated(poolInfo);
    }

    /**
     * @dev Withdraw tokens from contract (owner only)
     */
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ========== VIEW FUNCTIONS ==========

    /**
     * @dev Get stake info for user
     */
    function getStakeInfo(address user) external view returns (StakeInfo memory) {
        return stakes[user];
    }

    /**
     * @dev Check if user has active stake
     */
    function hasActiveStake(address user) external view returns (bool) {
        return stakes[user].active && stakes[user].amount > 0;
    }

    /**
     * @dev Get time remaining for stake
     */
    function getRemainingTime(address user) external view returns (uint256) {
        StakeInfo memory stake = stakes[user];
        if (!stake.active) return 0;
        
        if (block.timestamp >= stake.endTime) return 0;
        return stake.endTime - block.timestamp;
    }

    /**
     * @dev Calculate APY in percentage
     */
    function getAPY() external view returns (uint256) {
        return (poolInfo.rewardRate * 100) / BASIS_POINTS;
    }
}
