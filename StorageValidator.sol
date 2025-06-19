// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////////////////
            Abstract
///////////////////////////////////*/
/// @title Validator
/// @notice Abstract base contract for validation logic
/// @dev Provides common validation functionality and error handling
abstract contract ValidatorBase {

    /*///////////////////////////////////
            State variables
    ///////////////////////////////////*/
    ///@notice constant variables to control storage state of a contract
    uint8 internal constant TRUE = 1;
    uint8 internal constant FALSE = 2;

    ///@notice Mapping to store contract addresses. TRUE == 1 | FALSE == 2.
    mapping(address studentContract => uint8 contractStatus) internal s_alreadyStored;

    /*///////////////////////////////////
                Errors
    ///////////////////////////////////*/
    /// @notice Error thrown when trying to store an existing contract
    error Validator_AddressAlreadyStored(address _contract);
    /// @notice Error thrown when invalid contract address detected
    error Validator_InvalidAddress(address _testContract);

    /*///////////////////////////////////
                Modifiers
    ///////////////////////////////////*/
    /// @notice Modifier to check if the address is valid and not already stored
    /// @param _storageAddress The address to check
    /// @dev This modifier is created to simplify the validation process and remove redundant checks
    modifier checks(address _storageAddress) {
        if (s_alreadyStored[_storageAddress] == TRUE) revert Validator_AddressAlreadyStored(_storageAddress);
        if (_storageAddress == address(0)) revert Validator_InvalidAddress(_storageAddress);
        s_alreadyStored[_storageAddress] = TRUE;
        _;
    }
}

/*///////////////////////////////////
            Interfaces
///////////////////////////////////*/
interface IStorage {

  function setMessage(string calldata _message) external;
  function getMessage() external view returns (string memory);
}

/// @title StorageValidator
/// @notice Contract for validating storage contract implementations
/// @dev Performs message consistency check against predefined expected value
contract StorageValidator is ValidatorBase {

    /*///////////////////////////////////
            State variables
    ///////////////////////////////////*/
    ///@notice Constant variable to store the Course ID
    uint256 private constant COURSE_ID = 1;
    ///@notice Constant string used as reference for validation
    string private constant EXPECTED_MESSAGE = "Hello Nebula";
    ///@notice constant variable to store the validation reward
    uint64 private constant EXAM_REWARD = 1e16;
    ///@notice constant variable to store the APPROVAL THRESHOLD
    uint8 private constant EXAM_THRESHOLD = 2;

    /*///////////////////////////////////
                    Events
    ///////////////////////////////////*/
    ///@notice event emitted when the validation is successful
    event StorageValidator_ValidationSuccess(address student, uint256 score, uint256 courseId, uint64 reward, bool status);
    ///@notice event emitted when the setMessage validation fails
    event StorageValidator_SetMessageFailed(address student, bytes errorEmitted);
    ///@notice error emitted when the getMessage validation fails
    event StorageValidator_GetMessageFailed(address student, bytes getImplementationError);
    ///@notice event emitted when the message receive is different than expected
    event StorageValidator_WrongReturn(address student, string messageStored, string expectedMessage);

    /*///////////////////////////////////
                Functions
    ///////////////////////////////////*/


    /**
        @notice Validates a storage contract implementation
        @dev Checks message consistency and updates registry on success
        @param _storageAddress Address of the storage contract to validate
        @custom:reverts Validator_InvalidAddress If zero address is provided
        @custom:reverts Validator_ValidationFailed If message doesn't match expected value
        @custom:emits Validator_TestApproval On successful validation
    */
    function validateStorage(address _storageAddress) checks(_storageAddress) external returns (bytes[] memory) {
        // if (s_alreadyStored[_storageAddress] == TRUE) revert Validator_AddressAlreadyStored(_storageAddress);
        // if (_storageAddress == address(0)) revert Validator_InvalidAddress(_storageAddress);
        // s_alreadyStored[_storageAddress] = TRUE;

        IStorage nebula = IStorage(_storageAddress);
        uint256 studentScore;
        string memory messageStored;

        try nebula.setMessage(EXPECTED_MESSAGE) {
            studentScore++;
        } catch (bytes memory setImplementationError) {
            emit StorageValidator_SetMessageFailed(msg.sender, setImplementationError);
        }

        try nebula.getMessage() returns(string memory messageStored_){
            messageStored = messageStored_;
            studentScore++;
        } catch (bytes memory getImplementationError) {
            emit StorageValidator_GetMessageFailed(msg.sender, getImplementationError);
        }

        if (keccak256(bytes(messageStored)) != keccak256(bytes(EXPECTED_MESSAGE))) {
            emit StorageValidator_WrongReturn(msg.sender, messageStored, EXPECTED_MESSAGE);
        } else {
            studentScore++;
        }
        
        if(studentScore >= EXAM_THRESHOLD){
            bytes[] memory bytesArg = new bytes[](5);
            bytesArg[0] = abi.encodePacked(msg.sender);
            bytesArg[1] = abi.encodePacked(EXAM_REWARD);
            bytesArg[2] = abi.encodePacked(COURSE_ID);
            bytesArg[3] = abi.encodePacked(studentScore);
            bytesArg[4] = abi.encodePacked(false); //only the last exam sends status == true
            
            emit StorageValidator_ValidationSuccess(msg.sender, studentScore, COURSE_ID, EXAM_REWARD, true);
            return bytesArg;
        }
    }
}