# Contract description

## Compiler
  The compiler version used for last tests is the 0.4.24

  `pragma solidity 0.4.24`

## SafeMaths
  This contract use the OpenZeppelin SafeMath library

    `/**
     * @title SafeMath by OpenZeppelin
     * @dev Math operations with safety checks that throw on error
     */
    library SafeMath {

        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a * b;
            assert(a == 0 || c / a == b);
            return c;
        }

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a / b;
            return c;
        }

        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            assert(c >= a);
            return c;
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            assert(b <= a);
            return a - b;
        }

    }`

## ERC20 Interface definition

  This contract implement the following ERC20 token interface definition for general use.

    `/**
     * @title ERC20Basic
     * @dev Simpler version of ERC20 interface
     * @dev see https://github.com/ethereum/EIPs/issues/179
     */
     contract ERC20Basic {
        function totalSupply() public view returns (uint256);
        function balanceOf(address who) public view returns (uint256);
        function transfer(address to, uint256 value) public returns (bool);
        function transferFrom(address from, address to, uint256 value) public returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
     }`

## Contract administration

  This contract implement a user level scheme for the administration. Mainly there are 3 levels:
  * 0 is a normal user
  * 1 is a basic admin
  * 2 is a master admin
  
  The administration contract let a master admin to set new admins. Also it implements a modifier to limit functions execution to a minimal admin level user.

    `/**
     * @title admined
     * @notice This contract is administered
     */
    contract admined {
        mapping(address => uint8) public level;
        //0 normal user
        //1 basic admin
        //2 master admin

        /**
        * @dev This contructor takes the msg.sender as the first master admin
        */
        constructor() internal {
            level[msg.sender] = 2; //Set initial admin to contract creator
            emit AdminshipUpdated(msg.sender,2);
        }

        /**
        * @dev This modifier limits function execution to the admin
        */
        modifier onlyAdmin(uint8 _level) { //A modifier to define admin-only functions
            require(level[msg.sender] >= _level );
            _;
        }

        /**
        * @notice This function transfer the adminship of the contract to _newAdmin
        * @param _newAdmin The new admin of the contract
        */
        function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public { //Admin can be set
            require(_newAdmin != address(0));
            level[_newAdmin] = _level;
            emit AdminshipUpdated(_newAdmin,_level);
        }

        /**
        * @dev Log Events
        */
        event AdminshipUpdated(address _newAdmin, uint8 _level);

    }`

## ICO Contract basic variables

  This contract uses the SafeMath library for uint256 numbers by default

    `contract TECHICO is admined {

        using SafeMath for uint256;`
  The actual state of the contract is handled by the variable "state" and have 5 stages and a Successful state

    `//This ico have 5 possible states
    enum State {
        Stage1,
        Stage2,
        Stage3,
        Stage4,
        Stage5,
        Successful
    }`

  The public variables are viewable by any users, they are:
  
    `//Time-state Related
    State public state = State.Stage1; //Set initial stage
    uint256 constant public SaleStart = 1527879600; //Human time (GMT): Friday, 1 de June de 2018 19:00:00
    uint256 public SaleDeadline = 1533063600; //Human time (GMT): Tuesday, 31 de July de 2018 19:00:00
    uint256 public completedAt; //Set when ico finish `

    `//Token-eth related
    uint256 public totalRaised; //eth collected in wei
    uint256 public totalDistributed; //Whole sale tokens distributed
    ERC20Basic public tokenReward; //Token contract address
    uint256 public hardCap = 31200000 * (10 ** 18); // 31.200.000 tokens
    mapping(address => uint256) public pending; //tokens pending to being transfered`

    `//Contract details
    address public creator;
    string public version = '0.1';`

    `//User rights handlers
    mapping (address => bool) public whiteList; //List of allowed to send eth`

    `//Price related
    uint256 rate = 3000;`

## Contract Logging events

  Most transactions on the contract are logged by the following events

  * `event LogFundrisingInitialized(address _creator);`
  * `event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);`
  * `event LogBeneficiaryPaid(address _beneficiaryAddress);`
  * `event LogContributorsPayout(address _addr, uint _amount);`
  * `event LogFundingSuccessful(uint _totalRaised);`

## State checker

  The contract implements a mofier to prevent execution after the contract is finished

    `//Modifier to prevent execution if ico has ended or is holded
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }`

## On deployment

  When the contract is being deployed there are some values that are set: creator, token address and initial admin level


    `/**
    * @notice ICO constructor
    * @param _addressOfTokenUsedAsReward is the token to distribute
    */
    constructor(ERC20Basic _addressOfTokenUsedAsReward ) public {

        creator = msg.sender; //Creator is set from deployer address
        tokenReward = _addressOfTokenUsedAsReward; //Token address is set during deployment

        emit LogFundrisingInitialized(creator);
    }`

    `/**
    * @dev This contructor takes the msg.sender as the first master admin
    */
    constructor() internal {
        level[msg.sender] = 2; //Set initial admin to contract creator
        emit AdminshipUpdated(msg.sender,2);
    }`

## Whitelist functionality

  This contract implement a whitelist scheme. Together to the User rights handlers previously defined, an admin as low as level 1 can add/remove users from whitelist

    `/**
    * @notice Whitelist function
    */
    function whitelistAddress(address _user, bool _flag) public onlyAdmin(1) {
        whiteList[_user] = _flag;
    }`

## Contribution

  The contribution handler have to deal the math operations to calculate the tokens to be receiber by the purchaser.

  If the ether is send directly to contract, the caller is forwarded to the contribute function.

      `/*
      * @dev Direct payments handler
      */
      function () public payable {

          contribute();

      }`

  It initially check if the funding is not already finished with the "notFinished" modifier.

     `/**
      * @notice contribution handler
      */
      function contribute() public notFinished payable {`

  Later it check if the funding already start and if the caller is whitelisted.

      `require(now > SaleStart);
      require(whiteList[msg.sender] == true); //User must be whitelisted`

  Update the amount of eth raised.

      `totalRaised = totalRaised.add(msg.value); //ether received updated`

  Make the base token purchase calculation.

      `//base tokens amount calculation
      uint256 tokenBought = msg.value.mul(rate);`

  Later, if there is any bonus by the stage of contract, it check and apply it.       

      `//Bonus calculation
      if(state == State.Stage1){

           tokenBought = tokenBought.mul(12);
           tokenBought = tokenBought.div(10); // 1.2 = 120% = 100+20%

      } else if(state == State.Stage2) {

           tokenBought = tokenBought.mul(115);
           tokenBought = tokenBought.div(100); // 1.15 = 115% = 100+15%

      } else if(state == State.Stage3) {

           tokenBought = tokenBought.mul(11);
           tokenBought = tokenBought.div(10); // 1.1 = 110% = 100+10%

      } else if(state == State.Stage4) {

           tokenBought = tokenBought.mul(105);
           tokenBought = tokenBought.div(100); // 1.05 = 105% = 100+5%

      }`

  Since tokens are delivered at end we must check internally if the tokens being sold are not more than the total amount of tokens on sale.

      `require(totalDistributed.add(tokenBought) <= hardCap);`

  Then the contract keep on ledge the tokens pending to claim and sum up the total tokens sold until now.

      `pending[msg.sender] = pending[msg.sender].add(tokenBought);
      totalDistributed = totalDistributed.add(tokenBought); //whole tokens sold updated`

  A logging is emited and the status check function is executed.

      `emit LogFundingReceived(msg.sender, msg.value, totalRaised);

      checkIfFundingCompleteOrExpired();      
    }`

## Tokens claim

  There are to ways the tokens can be claimed at the end of the ico:

  * User claim

        `/**
        * @notice Funtion to let users claim their tokens at the end of ico process
        */
        function claimTokensByUser() public{
            require(state == State.Successful);
            uint256 temp = pending[msg.sender];
            pending[msg.sender] = 0;
            require(tokenReward.transfer(msg.sender,temp));
            emit LogContributorsPayout(msg.sender,temp);
        }`

  * Admin claim

        `/**
        * @notice Funtion to let admins claim users tokens on behalf of them at the end of ico process
        */
        function claimTokensByAdmin(address _user) onlyAdmin(1) public{
            require(state == State.Successful);
            uint256 temp = pending[_user];
            pending[_user] = 0;
            require(tokenReward.transfer(_user,temp));
            emit LogContributorsPayout(_user,temp);
        }`

## Current status checks

  Every time a purchase is made (or by calling the "checkIfFundingCompleteOrExpired" function) the contract check the current state of the contract and check if it must be updated.

    `/**
    * @notice Process to check contract current status
    */
    function checkIfFundingCompleteOrExpired() public {

        if ( (totalDistributed == hardCap || now > SaleDeadline) && state != State.Successful){

            //remanent tokens are assigned to creator for later handle
            pending[creator] = tokenReward.balanceOf(address(this)).sub(totalDistributed);

            state = State.Successful; //ICO becomes Successful
            completedAt = now; //ICO is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            successful(); //and execute closure

        } else if(state == State.Stage1 && totalDistributed > 7200000*10**18 ) { //7.200.000*0.25=1.8M$

            state = State.Stage2;

        } else if(state == State.Stage2 && totalDistributed > 11200000*10**18 ) { //11.200.000*0.25=2.8M$

            state = State.Stage3;

        } else if(state == State.Stage3 && totalDistributed > 15200000*10**18) { //15.200.000*0.25=3.8M$

            state = State.Stage4;

        } else if(state == State.Stage4 && totalDistributed > 22000000*10**18) { //22.000.000*0.25=5.5M$

            state = State.Stage5;

        }
    }`

## Finish handler

  Only when the status becomes Successful the contract execute the "successful" funtion that will send back the remaining tokens and eth to the contract creator.

    `/**
    * @notice successful closure handler
    */
    function successful() public {
        //When successful
        require(state == State.Successful);
        //Remanent tokens handle
        uint256 temp = pending[creator];
        pending[creator] = 0;
        require(tokenReward.transfer(creator,temp));

        emit LogContributorsPayout(creator,temp);

        //After successful eth is send to creator
        creator.transfer(address(this).balance);

        emit LogBeneficiaryPaid(creator);

    }`

## External tokens handling

  In case any other token not related to the ico get inside the contract address, there is a function to move them.

    `/**
    * @notice Function to claim any token stuck on contract
    */
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(state == State.Successful); //Only when sale finish
        require(_address != address(tokenReward));

        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(msg.sender,remainder); //Transfer tokens to admin

    }`
