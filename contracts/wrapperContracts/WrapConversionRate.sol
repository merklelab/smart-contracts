pragma solidity 0.4.18;


import "../ERC20Interface.sol";
import "../ConversionRates.sol";
import "./WrapperBase.sol";


contract WrapConversionRate is WrapperBase {

    ConversionRates conversionRates;

    //add token parameters
    ERC20     addTokenToken;
    uint      addTokenMinimalResolution; // can be roughly 1 cent
    uint      addTokenMaxPerBlockImbalance; // in twei resolution
    uint      addTokenMaxTotalImbalance;

    //set token control info parameters.
    ERC20[]     tokenInfoTokenList;
    uint[]      tokenInfoPerBlockImbalance; // in twei resolution
    uint[]      tokenInfoMaxTotalImbalance;

    //valid duration
    uint pendingValidDurationBlocks;

    //data indexes
    uint constant addTokenDataIndex = 0;
    uint constant tokenInfoDataIndex = 1;
    uint constant validDurationIndex = 2;
    uint constant numDataInstances = 3;

    //general functions
    function WrapConversionRate(ConversionRates _conversionRates, address _admin) public
        WrapperBase(PermissionGroups(address(_conversionRates)), _admin, numDataInstances)
    {
        require (_conversionRates != address(0));
        conversionRates = _conversionRates;
    }

    // add token functions
    //////////////////////
    function setAddTokenData(ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance) public onlyOperator {
        require(minimalRecordResolution != 0);
        require(maxPerBlockImbalance != 0);
        require(maxTotalImbalance != 0);

        //update data tracking
        setNewData(addTokenDataIndex);

        addTokenToken = token;
        addTokenMinimalResolution = minimalRecordResolution; // can be roughly 1 cent
        addTokenMaxPerBlockImbalance = maxPerBlockImbalance; // in twei resolution
        addTokenMaxTotalImbalance = maxTotalImbalance;
    }

    function approveAddTokenData(uint nonce) public onlyOperator {
        if(addSignature(addTokenDataIndex, nonce, msg.sender)) {
            // can perform operation.
            performAddToken();
        }
    }

    function performAddToken() internal {
        conversionRates.addToken(addTokenToken);

        conversionRates.addOperator(this);

        //token control info
        conversionRates.setTokenControlInfo(
            addTokenToken,
            addTokenMinimalResolution,
            addTokenMaxPerBlockImbalance,
            addTokenMaxTotalImbalance
        );

        //step functions
        int[] memory zeroArr = new int[](1);
        zeroArr[0] = 0;

        conversionRates.setQtyStepFunction(addTokenToken, zeroArr, zeroArr, zeroArr, zeroArr);
        conversionRates.setImbalanceStepFunction(addTokenToken, zeroArr, zeroArr, zeroArr, zeroArr);

        conversionRates.enableTokenTrade(addTokenToken);

        conversionRates.removeOperator(this);
    }

    function getAddTokenParameters() public view
        returns(uint nonce, ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance)
    {
        (, nonce) = getDataTrackingParameters(addTokenDataIndex);
        token = addTokenToken;
        minimalRecordResolution = addTokenMinimalResolution;
        maxPerBlockImbalance = addTokenMaxPerBlockImbalance; // in twei resolution
        maxTotalImbalance = addTokenMaxTotalImbalance;
        return(nonce, token, minimalRecordResolution, maxPerBlockImbalance, maxTotalImbalance);
    }

    function getAddTokenSignatures() public view returns (address[] signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(addTokenDataIndex);
        return(signatures);
    }

    //set token control info
    ////////////////////////
    function setTokenInfoData(ERC20 [] tokens, uint[] maxPerBlockImbalanceValues, uint[] maxTotalImbalanceValues)
        public
        onlyOperator
    {
        require(maxPerBlockImbalanceValues.length == tokens.length);
        require(maxTotalImbalanceValues.length == tokens.length);

        //update data tracking
        setNewData(tokenInfoDataIndex);

        tokenInfoTokenList = tokens;
        tokenInfoPerBlockImbalance = maxPerBlockImbalanceValues;
        tokenInfoMaxTotalImbalance = maxTotalImbalanceValues;
    }

    function approveTokenControlInfo(uint nonce) public onlyOperator {
        if(addSignature(tokenInfoDataIndex, nonce, msg.sender)) {
            // can perform operation.
            performSetTokenControlInfo();
        }
    }

    function performSetTokenControlInfo() internal {
        require(tokenInfoTokenList.length == tokenInfoPerBlockImbalance.length);
        require(tokenInfoTokenList.length == tokenInfoMaxTotalImbalance.length);

        uint minimalRecordResolution;

        for (uint i = 0; i < tokenInfoTokenList.length; i++) {
            (minimalRecordResolution, , ) =
                conversionRates.getTokenControlInfo(tokenInfoTokenList[i]);
            require(minimalRecordResolution != 0);

            conversionRates.setTokenControlInfo(tokenInfoTokenList[i],
                                                minimalRecordResolution,
                                                tokenInfoPerBlockImbalance[i],
                                                tokenInfoMaxTotalImbalance[i]);
        }
    }

    function getControlInfoPerToken (uint index) public view returns(ERC20 token, uint _maxPerBlockImbalance, uint _maxTotalImbalance) {
        require (tokenInfoTokenList.length > index);
        require (tokenInfoPerBlockImbalance.length > index);
        require (tokenInfoMaxTotalImbalance.length > index);

        return(tokenInfoTokenList[index], tokenInfoPerBlockImbalance[index], tokenInfoMaxTotalImbalance[index]);
    }

    function getTokenInfoNumToknes() public view returns(uint numSetTokens) {
        return tokenInfoTokenList.length;
    }

    function getTokenInfoData() public view returns(uint nonce, uint numSetTokens, ERC20[] tokenAddress, uint[] maxPerBlock, uint[] maxTotal) {
        (, nonce) = getDataTrackingParameters(tokenInfoDataIndex);
        return(nonce, tokenInfoTokenList.length, tokenInfoTokenList, tokenInfoPerBlockImbalance, tokenInfoMaxTotalImbalance);
    }

    function getTokenInfoSignatures() public view returns (address[] signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(tokenInfoDataIndex);
        return(signatures);
    }

    function getTokenInfoNonce() public view returns(uint nonce) {
        address[] memory signatures;
        (signatures, nonce) = getDataTrackingParameters(tokenInfoDataIndex);
        return nonce;
    }

    //valid duration blocks
    ///////////////////////
    function setValidDurationData(uint validDurationBlocks) public onlyOperator {
        require(validDurationBlocks > 5);

        //update data tracking
        setNewData(validDurationIndex);

        pendingValidDurationBlocks = validDurationBlocks;
    }

    function approveValidDurationData(uint nonce) public onlyOperator {
        if(addSignature(validDurationIndex, nonce, msg.sender)) {
            // can perform operation.
            conversionRates.setValidRateDurationInBlocks(pendingValidDurationBlocks);
        }
    }

    function getValidDurationBlocksData() public view returns(uint validDuration, uint nonce) {
        (, nonce) = getDataTrackingParameters(validDurationIndex);
        return(nonce, pendingValidDurationBlocks);
    }

    function getValidDurationSignatures() public view returns (address[] signatures) {
        uint nonce;
        (signatures, nonce) = getDataTrackingParameters(validDurationIndex);
        return(signatures);
    }
}
