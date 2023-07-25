// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Chessman {
    using Counters for Counters.Counter;
    Counters.Counter private _gameIds;

    address public admin;

    int256 public constant INITIAL_RATING = 800;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    struct Game {
        uint256 gameId;
        address whitePlayer;
        address blackPlayer;
        string gamePubKey;
        string gameDataWhite;
        string gameDataBlack;
        string gameResult;
        bool isAbandonedByWhite;
        bool isAbandonedByBlack;
    }

    struct GameDataRequest {
        uint256 gameId;
        string pubKey;
        string gameData;
    }

    struct User {
        address userAddress;
        int256 rating;
    }

    mapping(address => Game[]) public userGames;

    mapping(address => User) public users;

    address[] public userArr;

    mapping(uint256 => GameDataRequest[]) public gameDataRequests;

    Game[] public games;

    constructor() {
        admin = msg.sender;
    }

    function startGameRequest(address blackPlayerAddr) external {
        User memory whitePlayer = users[msg.sender];
        if (whitePlayer.userAddress == address(0)) {
            whitePlayer = User({
                userAddress: msg.sender,
                rating: INITIAL_RATING
            });
        }
        users[msg.sender] = whitePlayer;

        User memory blackPlayer = users[blackPlayerAddr];
        if (blackPlayer.userAddress == address(0)) {
            blackPlayer = User({
                userAddress: blackPlayerAddr,
                rating: INITIAL_RATING
            });
        }
        users[blackPlayerAddr] = blackPlayer;

        userArr.push(msg.sender);
        userArr.push(blackPlayerAddr);

        uint256 gameId = _gameIds.current();

        Game memory newGame = Game({
            gameId: gameId,
            whitePlayer: msg.sender,
            blackPlayer: blackPlayerAddr,
            gamePubKey: "",
            gameDataWhite: "",
            gameDataBlack: "",
            gameResult: "",
            isAbandonedByWhite: false,
            isAbandonedByBlack: false
        });

        games.push(newGame);

        userGames[msg.sender].push(newGame);
        userGames[blackPlayerAddr].push(newGame);

        _gameIds.increment();
    }

    function submitGameWhite(uint256 _gameId, string memory _gameHash) external {
        Game memory game = games[_gameId];
        game.gameDataWhite = _gameHash;
        games[_gameId] = game;
    }

    function submitGameBlack(uint256 _gameId, string memory _gameHash) external {
        Game memory game = games[_gameId];
        game.gameDataBlack = _gameHash;
        games[_gameId] = game;
    }

    function approveGameRequest(uint256 _gameId, string memory pubKey) external onlyAdmin {
        Game memory game = games[_gameId];
        game.gamePubKey = pubKey;
        games[_gameId] = game;
    }

    function finishGame(uint256 _gameId, string memory gameResult, int256 whiteRatingChange, int256 blackRatingChange) external onlyAdmin {
        Game memory game = games[_gameId];
        game.gameResult = gameResult;
        games[_gameId] = game;

        User memory whitePlayer = users[game.whitePlayer];
        whitePlayer.rating += whiteRatingChange;
        users[game.whitePlayer] = whitePlayer;

        User memory blackPlayer = users[game.blackPlayer];
        blackPlayer.rating += blackRatingChange;
        users[game.blackPlayer] = blackPlayer;
    }

    function abandonGame(uint256 _gameId, uint256 abandonedBy) external onlyAdmin {
        Game memory game = games[_gameId];
        if (abandonedBy == 0) {
            game.isAbandonedByWhite = true;
        } else {
            game.isAbandonedByBlack = true;
        }
        games[_gameId] = game;
    }

    function requestAccess(uint256 _gameId, string memory pubKey) external {
        GameDataRequest[] storage requests = gameDataRequests[_gameId];

        GameDataRequest memory newRequest = GameDataRequest({
            gameId: _gameId,
            pubKey: pubKey,
            gameData: ""
        });

        requests.push(newRequest);
        gameDataRequests[_gameId] = requests;
    }

    function addSignedData(uint256 _gameId, string memory _pubKey, string memory _signedData) external onlyAdmin {
        GameDataRequest[] storage requests = gameDataRequests[_gameId];
        
        for (uint256 i = 0; i < requests.length; i++) {
            if (keccak256(abi.encodePacked(requests[i].pubKey)) == keccak256(abi.encodePacked(_pubKey))) {
                requests[i].gameData = _signedData;
            }
        }

        gameDataRequests[_gameId] = requests;
    }
}
