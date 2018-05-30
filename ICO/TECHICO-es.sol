pragma solidity 0.4.24;
/**
* @title Contrato TECH ICO
* @dev TECH es un token que cumple con el estándar ERC-20
* Contacto: WorkChainCenters@gmail.com  www.WorkChainCenters.io
*/

/**
 * @title SafeMath por OpenZeppelin
 * @dev Operaciones matematicas con chequeos que cancelan la transacción ante error
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

}


/**
 * @title ERC20Basic
 * @dev Versión simple de la interface ERC20
 * @dev chequear https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title admined
 * @notice Este contrato es administrado
 */
contract admined {
    //Mapeo a los niveles de usuario
    mapping(address => uint8) public level;
    //0 Usuario Normal
    //1 Administrador básico
    //2 Administrador en jefe

    /**
    * @dev Este constructor toma al msg.sender como el primer administrador en jefe
    */
    constructor() internal {
        level[msg.sender] = 2; //Asigna la admnistración al creador del contrato
        emit AdminshipUpdated(msg.sender,2); //Registra la asignación de administrador
    }

    /**
    * @dev Este modificador limita la ejecución de funciones al administrador
    */
    modifier onlyAdmin(uint8 _level) { //Este modificador define funciones sólo para el administrador
        require(level[msg.sender] >= _level ); //Se requiere que el nivel de usuario sea mayor o igual a _level
        _;
    }

    /**
    * @notice Esta funcion transfiere la administración del contrato a _newAdmin
    * @param _newAdmin El nuevo administrador del contrato
    */
    function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public { //Sólo un administrador puede asignar
        require(_newAdmin != address(0)); //El nuevo administrador no puede ser la dirección cero
        level[_newAdmin] = _level; //El nuevo nivel se asigna
        emit AdminshipUpdated(_newAdmin,_level); //Registramos la asignación del administrador
    }

    /**
    * @dev Eventos de registro
    */
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

contract TECHICO is admined {

    using SafeMath for uint256;
    //Este ico tiene 5 posibles etapas y una etapa Successful(exitosa)
    enum State {
        Stage1,
        Stage2,
        Stage3,
        Stage4,
        Stage5,
        Successful
    }
    //Variables públicas

    //Relacionadas con tiempo-estado
    State public state = State.Stage1; //Se asigna estado inicial
    uint256 constant public SaleStart = 1527879600; //Tiempo humano (GMT): Viernes, 1 de Junio de 2018 19:00:00
    uint256 public SaleDeadline = 1533063600; //Tiempo humano (GMT): Martes, 31 de Julio de 2018 19:00:00
    uint256 public completedAt; //Se asigna al finalizar el ICO
    //Relacionadas con token-ether
    uint256 public totalRaised; //eth recolectado en wei
    uint256 public totalDistributed; //Todos los tokens vendidos
    ERC20Basic public tokenReward; //Dirección del contrato del token
    uint256 public hardCap = 31200000 * (10 ** 18); // 31.200.000 tokens
    mapping(address => uint256) public pending; //tokens pendientes de ser transferidos
    //Detalles del contrato
    address public creator; //Dirección del creador
    string public version = '0.1'; //Versión del contrato

    //Manejador de derechos de usuario
    mapping (address => bool) public whiteList; //Lista de permitidos de enviar fondos

    //Relacionadas al precio
    uint256 rate = 3000; //Tokens por unidad de ether

    //eventos para registros
    event LogFundrisingInitialized(address _creator);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);

    //Modofocador para prevenir ejecución si el ico terminó
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

    /**
    * @notice Constructor del ICO
    * @param _addressOfTokenUsedAsReward es el token a ser distribuido
    */
    constructor(ERC20Basic _addressOfTokenUsedAsReward ) public {

        creator = msg.sender; //El creador se asigna del publicador del contrato
        tokenReward = _addressOfTokenUsedAsReward; //La dirección del token se asigna en la publicación

        emit LogFundrisingInitialized(creator); //Registro de inicio del contrato
    }

    /**
    * @notice Función de Whitelist
    * @param _user Dirección de usuario a ser modificada en la lista
    * @param _flag Estatus a asignar en la lista
    */
    function whitelistAddress(address _user, bool _flag) public onlyAdmin(1) {
        whiteList[_user] = _flag; //Se asigna el estatus al usuario en la lista
    }

    /**
    * @notice manejador de contribuciones
    */
    function contribute() public notFinished payable {
        require(now > SaleStart); //El momento actual debe ser mayor que el momento de inicio del ico
        require(whiteList[msg.sender] == true); //el usuario debe estar en whitelist

        totalRaised = totalRaised.add(msg.value); //se actualiza el ether recibido

        uint256 tokenBought = msg.value.mul(rate); //se calculan los tokens base

        //Cálculo de Bonos
        if(state == State.Stage1){ //Si el estado actual es 1
            //+20% bono
            tokenBought = tokenBought.mul(12);
            tokenBought = tokenBought.div(10); // 1.2 = 120% = 100+20%

        } else if(state == State.Stage2) { //Si el estado actual es 2
            //+15% bono
            tokenBought = tokenBought.mul(115);
            tokenBought = tokenBought.div(100); // 1.15 = 115% = 100+15%

        } else if(state == State.Stage3) { //Si el estado actual es 3
            //+10 bono
            tokenBought = tokenBought.mul(11);
            tokenBought = tokenBought.div(10); // 1.1 = 110% = 100+10%

        } else if(state == State.Stage4) { //Si el estado actual es 4
            //+5% bono
            tokenBought = tokenBought.mul(105);
            tokenBought = tokenBought.div(100); // 1.05 = 105% = 100+5%

        }

        require(totalDistributed.add(tokenBought) <= hardCap); //El monto total después de sumar no puede ser mayor que el hardCap

        pending[msg.sender] = pending[msg.sender].add(tokenBought); //El balance pendiente de distribuir se actualiza
        totalDistributed = totalDistributed.add(tokenBought); //Todos los tokens vendidos se actualiza

        emit LogFundingReceived(msg.sender, msg.value, totalRaised); //Registramos la compra

        checkIfFundingCompleteOrExpired(); //Se ejecuta chequeo de estado
    }

    /**
    * @notice Función para que los usuarios reclamen sus tokens al temrinar el ico
    */
    function claimTokensByUser() public{
        require(state == State.Successful); //Terminado el ico
        uint256 temp = pending[msg.sender]; //Obtener el balance pendiente del usuario
        pending[msg.sender] = 0; //Limpiarlo
        require(tokenReward.transfer(msg.sender,temp)); //Tratar de transferir
        emit LogContributorsPayout(msg.sender,temp); //Registrar el reclamo
    }

    /**
    * @notice Función para que un administrador reclame los tokens por un usuario al temrinar el ico
    * @param _user Objetivo del reclamo de tokens
    */
    function claimTokensByAdmin(address _user) onlyAdmin(1) public{
        require(state == State.Successful); //Terminado el ico
        uint256 temp = pending[_user]; //Obtener el balance pendiente del usuario
        pending[_user] = 0; //Limpiarlo
        require(tokenReward.transfer(_user,temp)); //Tratar de transferir
        emit LogContributorsPayout(_user,temp); //Registrar el reclamo
    }

    /**
    * @notice Proceso para chequear el estado actual del contrato
    */
    function checkIfFundingCompleteOrExpired() public {

        if ( (totalDistributed == hardCap || now > SaleDeadline) && state != State.Successful){ //Si se alcanza el hardCap o la fecha final y aún no se marca exitoso

            pending[creator] = tokenReward.balanceOf(address(this)).sub(totalDistributed); //Se asignan los tokens restantes al creador

            state = State.Successful; //Se marca el ICO como exitoso
            completedAt = now; //Tiempo de finalización

            emit LogFundingSuccessful(totalRaised); //Registramos el final
            successful(); //Se ejecuta el cierre

        } else if(state == State.Stage1 && totalDistributed > 7200000*10**18 ) { //Si los tokens vendidos son igual o mayor a 7.200.000*0.25=1.8M$ y estamos en etapa 1

            state = State.Stage2; //Pasamos de estado

        } else if(state == State.Stage2 && totalDistributed > 11200000*10**18 ) { //Si los tokens vendidos son igual o mayor a 11.200.000*0.25=2.8M$ y estamos en etapa 2

            state = State.Stage3; //Pasamos de estado

        } else if(state == State.Stage3 && totalDistributed > 15200000*10**18) { //Si los tokens vendidos son igual o mayor a 15.200.000*0.25=3.8M$ y estamos en etapa 3

            state = State.Stage4; //Pasamos de estado

        } else if(state == State.Stage4 && totalDistributed > 22000000*10**18) { //Si los tokens vendidos son igual o mayor a 22.000.000*0.25=5.5M$ y estamos en etapa 4

            state = State.Stage5; //Pasamos de estado

        }
    }

    /**
    * @notice Manejador de cierre exitoso
    */
    function successful() public {
        require(state == State.Successful); //Al concluir
        uint256 temp = pending[creator]; //Manejamos los tokens restantes
        pending[creator] = 0; //Limpiamos el balance
        require(tokenReward.transfer(creator,temp)); //Tratamos de transferir

        emit LogContributorsPayout(creator,temp); //Registramos la transacción

        creator.transfer(address(this).balance); //Se envía el ether al creador

        emit LogBeneficiaryPaid(creator); //Registramos la transacción

    }

    /**
    * @notice Función para reclamar tokens atrapados en el contrato
    * @param _address Dirección del token objetivo
    */
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(state == State.Successful); //Sólo cuando termine la venta
        require(_address != address(tokenReward)); //El token objetivo debe ser diferente del de la venta

        uint256 remainder = _address.balanceOf(this); //Se chequean los tokens restantes
        _address.transfer(msg.sender,remainder); //Se transfieren al administrador

    }

    /*
    * @dev Manejador de pagos directos
    */
    function () public payable {

        contribute(); //Redirección a la función de contribución

    }
}
