
/**
 * This software is a subject to ATFSLab License Agreement.
 * No use or distribution is allowed without written permission from ATFSLab.
 * https://www.atfslab.io
 * 
 * last modified : Nov.26 2017
 * version       : 0.2
 */

pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks
 */
contract SafeMath 
{
  function safeMul( uint256 a, uint256 b ) internal constant returns (uint256) 
  {
    uint256 c = a * b;
    assert( a == 0 || c / a == b );
    return c;
  }

  function safeDiv( uint256 a, uint256 b ) internal constant returns (uint256) 
  {
    assert( b > 0 ); 
    uint256 c = a / b;
    assert( a == b * c + a % b );
    return c;
  }

  function safeSub( uint256 a, uint256 b ) internal constant returns (uint256) 
  {
    assert( a >= b );
    return a - b;
  }

  function safeAdd( uint256 a, uint256 b ) internal constant returns (uint256) 
  {
    uint256 c = a + b;
    assert( c >= a && c >= b );
    return c;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 
{
  uint256 public mTotalSupply;

  function balanceOf( address who ) public constant returns (uint256);

  function allowance( address owner, address spender ) public constant returns (uint256);
  function approve( address spender, uint256 value ) public returns (bool);

  function transfer( address to, uint256 value ) public returns (bool);
  function transferFrom( address from, address to, uint256 value ) public returns (bool);
  
  event Transfer( address indexed from, address indexed to, uint256 value );
  event Approval( address indexed owner, address indexed spender, uint256 value );
}

/**
 * @title ERC20 token
 * @dev ERC20 token implementation
 */
contract ERC20Token is SafeMath, ERC20
{
  mapping( address => uint256 ) mBalances;
  mapping( address => mapping( address => uint256 ) ) mAllowed;
  
 /**
  * @dev returns the balance of the specified address.
  * @param owner address The address to get the the balance of.
  * @return uint256 the amount owned by the address.
  */
  function balanceOf( address owner ) public constant returns (uint256) 
  {
    return mBalances[ owner ];
  }
  
  /**
   * @dev Function to check the amount of tokens that an owner has allowed to a spender.
   * @param owner address The address which owns the tokens.
   * @param spender address The address which wants to spend the tokens.
   * @return uint256 the amount of tokens allowed to spend by the spender.
   */
  function allowance( address owner, address spender ) public constant returns (uint256) 
  {
    return mAllowed[ owner ][ spender ];
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender address The address which are allowed to spend message sender's token.
   * @param value uint256 The amount of tokens to be spent.
   */
  function approve( address spender, uint256 value ) public returns (bool) 
  {
    //
    // To change the approved amount you first have to reduce 
    //  the addresses'allowance to zero by calling - approve( spender, 0 )
    //  if it is not already 0 to mitigate the race condition described here:
    // 
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    //
    require( ( value == 0 ) || ( mAllowed[ msg.sender ][ spender ] == 0 ) );

    mAllowed[ msg.sender ][ spender ] = value;
    
    Approval( msg.sender, spender, value );
    
    return true;
  }
  
  /**
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier checkPayloadSize( uint256 size ) 
  {
    if( msg.data.length < size + 4 ) {
      throw;
    }
    _;
  }
  
  /**
  * @dev transfer token to the address "to"
  * @param to address The address to transfer to.
  * @param value uint256 The amount to be transferred.
  */
  function transfer( address to, uint256 value ) public checkPayloadSize( 2*32 ) returns (bool) 
  {
    mBalances[ msg.sender ] = safeSub( mBalances[ msg.sender ], value );
    mBalances[ to ]         = safeAdd( mBalances[ to ], value );
    
    Transfer( msg.sender, to, value );
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address from which to send tokens
   * @param to address The address to transfer to.
   * @param value uint256 The amout of tokens to be transfered
   */
  function transferFrom( address from, address to, uint256 value ) public returns (bool) 
  {
    uint256 allowed = mAllowed[ from ][ msg.sender ];
     
    // will throw if allowed < value
    mAllowed[ from ][ msg.sender ] = safeSub( allowed, value );

    mBalances[ from ] = safeSub( mBalances[ from ], value );
    mBalances[ to ]   = safeAdd( mBalances[ to ], value );
    
    Transfer( from, to, value );
    return true;
  }
}

/**
 * @title Ownable
 * @dev Ownable provides basic authorization control or permission
 */
contract Ownable 
{
  address public mOwner;

  /**
   * @dev The Constructor sets `owner` of the contract with the sender
   */
  function Ownable( ) public 
  {
    mOwner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner( ) 
  {
    require( msg.sender == mOwner );
    _;
  }

  /**
   * @dev set new owner of contract
   * @param newOwner The address of new owner
   */
  function setNewOwner( address newOwner ) public onlyOwner 
  {
    if( newOwner != address(0) ) 
    {
      mOwner = newOwner;
    }
  }
}

/**
 * @title Pausable
 * @dev implements an emergency "pause" of crowdsale.
 */
contract Pausable is Ownable 
{
  event Pause( );
  event Resume( );

  bool public mPaused = false;

  /**
   * @dev modifier to check "not paused" state
   */
  modifier notPaused( ) {
    require( !mPaused );
    _;
  }

  /**
   * @dev modifier to check "paused" state
   */
  modifier paused( ) {
    require( mPaused );
    _;
  }

  /**
   * @dev called to pause crowdsale
   */
  function pause( ) public onlyOwner notPaused returns (bool) {
    mPaused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function resume( ) public onlyOwner paused returns (bool) {
    mPaused = false;
    resume( );
    return true;
  }
}

/**
 * @title ATFS Lab Token
 * @dev ERC20-compatible ATFS Lab Token - ATFS
 */
contract ATFSLabToken is ERC20Token, Pausable
{
  // token
  string  public constant mName 	 = 'ATFS Lab Token';
  string  public constant mSymbol 	 = 'ATFS';
  uint8   public constant mDecimals 	 = 6;
  
  // ICO constant
  uint256 public constant INITIAL_SUPPLY = 600 * ( 10 ** 6 ) * ( 10**uint256( mDecimals ) );
  uint256 public constant MIN_INVEST	 = ( 1*(10**18) )/10;	// 0.1 ether
  uint256 public constant MIN_ICO_PERIOD = 30;
  
  uint256 public mICOStart	= 1515592800;		// Jan.10.2018 14:00:00
  uint256 public mICOPeriod	= 30;

  uint256[] public mTokenBonus;  
  
  // misc.
  uint64  public constant SEC_PER_DAY	 = 24*60*60;
  
  //
  // status  
  //
  mapping( address => uint256 ) mTokenForClaim;
  
  // the amount of tokens sold during crowdsale
  uint256 public mTokenSold = 0; 	
  
  // multisig address to which all ethers will be sent
  address public mMultiSig;

  // event  
  event Burn( address burner, uint256 value );
  event Mint( address minter, uint256 value );
  event PayableCalled( bool called );
  
  /**
   * @dev ATFS Token Constructor
   */
  function ATFSLabToken( ) public 
  {
    mTotalSupply = INITIAL_SUPPLY;       
    mBalances[ msg.sender ] = INITIAL_SUPPLY;
    
    initTokenBonus( );
  }
  
  /**
   * @dev fallback function when receiving Ether. shold be "payable"
   */
  function( ) public payable 
  {
    PayableCalled( true );
    
    invest_internal( msg.sender, msg.value, true );
  }

  /**
   * @dev called when investor invests with another coin than ETH
   * @param value uint256 coin shold be calculated outside in the unit of wei
   */
  function invest( uint256 value ) public onlyOwner 
  {
    invest_internal( msg.sender, value, false );
  }
  
  /**
   * @dev common call from fallback, and invest( )
   * @param investor address investor address
   * @param value uint256 wei
   * @param real bool set to true for real eth transfer, false for pseudo investment
   */
  function invest_internal( address investor, uint256 value, bool real ) private notPaused
  {
    if( value < MIN_INVEST ) 
      throw;
      
    if( !crowdsaleOn( ) ) 
      throw;
    
    uint256 tokens = calcTokens( value );
    
    uint256 sold = safeAdd( mTokenSold, tokens );

    if( mTotalSupply < sold )
      throw;
      
    mTokenForClaim[ investor ] = safeAdd( mTokenForClaim[ investor ], tokens );

    // we are in the context of investor. 
    // transferFrom( mOwner, investor, tokens );
     
    mTokenSold = sold;
    
    // if real transfer of ether, send ether to multisig address
    if( real && ( mMultiSig != address( 0 ) ) )
    {
      // 
      // when send( ) fails, it will just return false, not throw exception
      // cf. address.transfer( )
      //
      if( !mMultiSig.send( value ) ) 
        throw; 
    }
    
    // we are in the context of investor
    // Transfer( this, investor, tokens );
  }
  
  /**
   * @dev token claim from investor, executed in the context of investor
   */
  function claim( ) public notPaused returns (bool)
  {
    uint256 tokens = mTokenForClaim[ msg.sender ];
    
    if( tokens > 0 )
    {
      mBalances[ mOwner ] = safeSub( mBalances[ mOwner ], tokens );
      mBalances[ msg.sender ] = safeAdd( mBalances[ msg.sender ], tokens );
      mTokenForClaim[ msg.sender ] = 0;
      Transfer( mOwner, msg.sender, tokens );
      return true;
    }
    else
      throw;
  }
  
  /**
   * @dev calculate the number of token for wei invested
   */
  function calcTokens( uint256 value ) public returns ( uint256 )
  {
    uint32 idx = (uint32)( ( now - mICOStart ) / SEC_PER_DAY );
    uint256 ret = value * 2500 / ( 10**18 );
    
    if( idx >= MIN_ICO_PERIOD )	// no bonus
      return ret;
    
    return ( ret + ret * mTokenBonus[ idx ] / 100 );
  }

  /**
   * @dev ERC20 interface
   */
  function transfer( address to, uint256 value ) public notPaused returns (bool)
  {
    return super.transfer( to, value );
  }

  /**
   * @dev ERC20 interface
   */
  function transferFrom( address from, address to, uint256 value ) public notPaused returns (bool)  
  {
    return super.transferFrom( from, to, value );
  }

  /**
   * @dev ERC20 interface
   */
  function approve( address spender, uint256 value) public notPaused returns (bool) 
  {
    return super.approve( spender, value );
  }
  
  /**
   * @dev burn token supplied
   * @param value uint256 the amount of tokens to burn
   */
  function burn( uint256 value ) public onlyOwner 
  {
    require( value > 0);

    // must be owner
    address burner = msg.sender;
    
    mBalances[ burner ] = safeSub( mBalances[ burner ], value );
    mTotalSupply 	= safeSub( mTotalSupply, value );
    
    Burn( burner, value );
  }
  
  /**
   * @dev mint token supply
   * @param value uint256 the amount of tokens to mint
   */
  function mint( uint256 value ) public onlyOwner
  {
    require( value > 0 );
    
    // must be owner
    address minter = msg.sender;
    
    mBalances[ minter ] = safeAdd( mBalances[ minter ], value );
    mTotalSupply      = safeAdd( mTotalSupply, value );
    
    Mint( minter, value );
  }
  
  /**
   * @dev set multisig address
   * @param addr address multisig address
   */
  function setMultiSig( address addr ) public onlyOwner
  {
    mMultiSig = addr;
  }
  
  function getMultiSig( ) public returns (address)
  {
    return mMultiSig;
  }

  /**
   * @dev check whether crowd-sale is on
   */
  function crowdsaleOn( ) private returns (bool)
  {
    // 
    // now : uint, sec, current block timestamp, == block.timestamp
    //
    if( now >= mICOStart &&  ( ( now - mICOStart )/SEC_PER_DAY ) < mICOPeriod )
      return true;
    return false;
  }
  
  /**
   * @dev set ICOStart day in UTC
   */
  function setICOStart( uint256 utc ) public onlyOwner
  {
    mICOStart = utc;
  }
  
  /**
   * @dev set ICOPeriod in days
   */
  function setICOPeriod( uint256 days ) public onlyOwner
  {
    mICOPeriod = days;
  }
  
  /**
   * @dev set token bonus rate
   */
  function initTokenBonus( ) private
  {
    mTokenBonus.push( 40 );
    mTokenBonus.push( 40 );    
    mTokenBonus.push( 40 );   	// 3-days
                      
    mTokenBonus.push( 30 );
    mTokenBonus.push( 30 );    
    mTokenBonus.push( 30 );    
    mTokenBonus.push( 30 );
    mTokenBonus.push( 30 );	// 5	  
                      
    mTokenBonus.push( 20 );    
    mTokenBonus.push( 20 );
    mTokenBonus.push( 20 );
    mTokenBonus.push( 20 );    
    mTokenBonus.push( 20 );    
    mTokenBonus.push( 20 );
    mTokenBonus.push( 20 );    	// 7
                      
    mTokenBonus.push( 10 );    
    mTokenBonus.push( 10 );
    mTokenBonus.push( 10 );    
    mTokenBonus.push( 10 );    
    mTokenBonus.push( 10 );
    mTokenBonus.push( 10 );    
    mTokenBonus.push( 10 );    	// 7
                      
    mTokenBonus.push( 5 );	
    mTokenBonus.push( 5 );    
    mTokenBonus.push( 5 );    
    mTokenBonus.push( 5 );
    mTokenBonus.push( 5 ); 	// 5
                      
    mTokenBonus.push( 0 );    
    mTokenBonus.push( 0 );
    mTokenBonus.push( 0 );    
  }
}  


  
  
  
  
  
