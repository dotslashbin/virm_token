// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./library/IUniswapV2Router02.sol"; 
import "./library/IFactory.sol"; 
import "./Utils.sol";
import "./Admin.sol";
import "./Stakeable.sol";

contract VIRMT is VirmAdmin, Context, IERC20, IERC20Metadata, Ownable, Stakeable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Contract Properties
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint private _percentage_multiplier; 
    uint8 constant _decimal = 18; 

    // Router
    IUniswapV2Router02 private _router;
    address private _pair;

    // Tools
    using VirmTools for uint; 

    // Taxation Wallets
    address private _devWallet;
    address private _marketingWallet;
    address private _rewardsWallet;

    // Tax values
    uint _autoLPTax;
    uint _marketingTax;
    uint _burnTax;
    uint _rewardsTax;
    uint _devTax;

    uint _buyTax;
    uint _sellTax; 

    // EVENTS
    event AddWalletExemption(address input);
    

    constructor(uint multiplierValue, uint autoLPTaxValue, uint marketingTaxValue, uint burnTaxValue, uint rewardsTaxValue, uint devTaxValue, address routerAddress, address dev, address marketing, address rewards) {
        
        // Initializing token identity
        _name = "VIRM token";
        _symbol = "VIRM70" ;

        // Initializing router
        _router = IUniswapV2Router02(routerAddress);
        _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        // Initializing contract configurations
        _percentage_multiplier = multiplierValue; 
        
        // Initializing taxation wallets
        _devWallet = dev;
        _marketingWallet = marketing;
        _rewardsWallet = rewards;

        // Initializing tax values
        _autoLPTax = autoLPTaxValue;
        _marketingTax = marketingTaxValue;
        _burnTax = burnTaxValue;
        _rewardsTax = rewardsTaxValue;
        _devTax = devTaxValue;

        _mint(msg.sender,100000000 ether);
    }

    // ------------------ PRIVATE FUCTIONS: start ------------------------------------------------------ //

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _takeTax(uint taxValue, address wallet, uint256 amount) private returns(uint256 taxAmount) {

        // Checks to see if the address accessing is an excempted address
        if(amount > 0 && taxValue > 0) {
            taxAmount = VirmTools.getPercentageValue(taxValue, amount, _percentage_multiplier);
            _balances[wallet] += taxAmount;
            return taxAmount;
        }

        return 0;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
        }

        if(!_IsWalletExcempted(to)) {
            if(from == _pair) { // BUY
                amount -= _takeTax(_marketingTax, _marketingWallet, amount); // Marketing tax
                amount -= _takeTax(_autoLPTax, address(this), amount); // Liquidity tax goes back to the contract
            } else if(to == _pair) { // SELL
                amount -= _takeTax(_rewardsTax, _rewardsWallet, amount); // Rewards tax
                amount -= _takeTax(_devTax, _devWallet, amount); // Dev tax

            // Burn
            // uint256 burnAmount = VirmTools.getPercentageValue(_burnTax, amount, _percentage_multiplier);
            // _burn(address(0), burnAmount); 
            // amount -= burnAmount; 
            }
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    // ------------------ PRIVATE FUCTIONS: end ------------------------------------------------------ //

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function burnTax() public view returns(uint) {
        return _burnTax;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    function devWallet() public view returns(address) {
        return _devWallet;
    }

    function devTax() public view returns(uint) {
        return _devTax;
    }

    function ExcemptedWallets() onlyOwner public view returns(address[] memory) {
        return _FetchExcemptedWallets();
    }

    function ExemptWallet(address input) onlyOwner public {
        _InitTaxExcemptionForAddress(input); 
        emit AddWalletExemption(input); 
    }

    function hasStake(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = CalculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
        return summary;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function marketingWallet() public view returns(address) {
        return _marketingWallet;
    }

    function marketingTax() public view returns(uint) {
        return _marketingTax;
    }

    function pair() public view returns(address) {
        return _pair;
    }

    function rewardsWallet() public view returns(address) {
        return _rewardsWallet;
    }

    function rewardsTax() public view returns(uint) {
        return _rewardsTax;
    }

    function router() public view returns(IUniswapV2Router02) {
        return _router;
    }

    function setAutoLPTax(uint value) onlyOwner public {
        _autoLPTax = value;
    }

    function setBurnTax(uint value) onlyOwner public {
        _burnTax = value;
    }

    function setDevWallet(address value) onlyOwner public {
        require(value != address(0), "You cannot set a null address as tax wallet"); 
        require(value != address(this), "You cannot use this address as tax wallet");
        require(value != _marketingWallet, "You cannot use this address as tax wallet");
        require(value != _rewardsWallet, "You cannot use this address as tax wallet");

        _devWallet = value;
    }

    function setMarketingWallet(address value) onlyOwner public {
        require(value != address(0), "This requires a valid address");
        require(value != address(this), "You cannot use this address as tax wallet");
        require(value != _devWallet, "You cannot use this address as tax wallet");
        require(value != _rewardsWallet, "You cannot use this address as tax wallet");

        _marketingWallet = value;
    }

    function setMarketingTax(uint value) onlyOwner public {
        _marketingTax = value; 
    }

    function setPercentageMultiplier(uint value) onlyOwner public {
        require(value > 0, "Multiplier must contain a value greater than 0"); 
        _percentage_multiplier = value;
    }

    function setRewardsWallet(address value) onlyOwner public {
        require(value != address(0), "This requires a valid address");
        require(value != address(this), "You cannot use this address as tax wallet");
        require(value != _devWallet, "You cannot use this address as tax wallet");
        require(value != _marketingWallet, "You cannot use this address as tax wallet");

        _rewardsWallet = value;
    }

    function setRewardsTax(uint value) onlyOwner public {
        _rewardsTax = value;
    }

    function setRouter(address value) onlyOwner public {
        require(value != address(0), "You have to set a valid address"); 
        require(value != address(this), "The address cannot be this contract's address"); 
        _router = IUniswapV2Router02(value);
    }

    function stake(uint256 _amount) public {
      require(_amount < _balances[msg.sender], "DevToken: Cannot stake more than you own");

        _stake(_amount);
        _burn(msg.sender, _amount);
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function withdrawStake(uint256 amount, uint256 stake_index)  public {

      uint256 amount_to_mint = _withdrawStake(amount, stake_index);
      // Return staked tokens to user
      _mint(msg.sender, amount_to_mint);
    }
}