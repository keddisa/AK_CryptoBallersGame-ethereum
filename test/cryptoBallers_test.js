var CryptoBallers = artifacts.require('CryptoBallers');
var { expectThrow, expectEvent } = require('./helpers.js');

contract('CryptoBallers contract Tests', async (accounts) => {
    let owner = accounts[0];
    let player1 = accounts[1];
    let player2 = accounts[2];
    let contract;

    let getBaller = async (id) => {
        let baller = await contract.ballers.call(id);
        let name = baller[0];
        let level = parseInt(baller[1]); // convert from BN to int
        let offenseSkill = parseInt(baller[2]); // convert from BN to int
        let defenseSkill = parseInt(baller[3]); // convert from BN to int
        let winCount = parseInt(baller[4]); // convert from BN to int
        let lossCount = parseInt(baller[5]); // convert from BN to int
        return {name: name, level: level, offenseSkill: offenseSkill, defenseSkill: defenseSkill, winCount: winCount, lossCount: lossCount};
    }

    beforeEach(async () => {
        contract = await CryptoBallers.deployed();
    })

    describe('constructor() test', () => {
        // it('election name should be set in constructor', async () => {
        //     assert.equal(name, "");
        // })

        it('Should not have any ballers', async() => {
            let length = await contract.getNumBallers.call();
            assert.equal(length, 0);
        })
    })

    describe('claimFreeBaller() tests', () => {
        it('Can claim free baller', async () => {
            await contract.claimFreeBaller({ from: player1 });
        })

        it('Free baller info check', async () => {
            let baller = await getBaller(0);
            assert.equal(baller.name, "Free Baller");
            assert.equal(baller.level, 1);
            assert.equal(baller.defenseSkill, 30);
            assert.equal(baller.offenseSkill, 30);
            assert.equal(baller.winCount, 0);
            assert.equal(baller.lossCount, 0);
        })

        it('Cannot claim two free ballers', async () => {
            let tx = contract.claimFreeBaller({ from: player1 });
            await expectThrow(tx);
        })

    })

    describe('buyBaller() tests', () => {
        it('Cannot buy baller without transfering funds', async () => {
            try {
                let tx = await contract.buyBaller({ from: player2 });
                assert(false);
            } catch(err) {
                assert(err);
            }
        })

        // it('Cannot buy baller without transfering funds', async () => {
        //     let tx = contract.buyBaller({ from: player2 });
        //     await expectThrow(tx);
        // })

        it('Can buy baller with transfering funds', async () => {
            await contract.buyBaller({ from: player2, value: web3.utils.toWei('0.1', 'ether') });
        })


        
        it('Bought baller info check', async () => {
            let baller = await getBaller(1);
            assert.equal(baller.name, "Bought Baller");
            assert.equal(baller.level, 1);
            assert.equal(baller.defenseSkill, 50);
            assert.equal(baller.offenseSkill, 50);
            assert.equal(baller.winCount, 0);
            assert.equal(baller.lossCount, 0);
        })

    })

    describe('playBall() tests', () => {
        it('None baller owner cannot play with baller', async () => {
            let tx = contract.playBall(0, 1, { from: player2 });
            await expectThrow(tx);
        })

        it('Baller owner can play with baller', async () => {
            await contract.playBall(1, 0, { from: player2 });
        })

        it('A new baller is not created if level is less than 5', async () => {
            let baller = getBaller(2);
            await expectThrow(baller);
        })

    })

    describe('getBallersByOwner() tests', () => {
        it('Can call function', async () => {
            await contract.buyBaller({ from: player1, value: web3.utils.toWei('0.1', 'ether') });
            let ballers = await contract.getBallersByOwner( player1 );
        })
        

        it('Ballers info check', async () => {
            let ballers = await contract.getBallersByOwner(player1);
            assert.equal(ballers.length, 2)
            let baller1 = await getBaller(ballers[0]);
            assert.equal(baller1.name, "Free Baller");
            let address1 = await contract.ballersOwners(ballers[0]);
            assert.equal(address1, player1)
            let baller2 = await getBaller(ballers[1]);
            assert.equal(baller2.name, "Bought Baller");
            let address2 = await contract.ballersOwners(ballers[1]);
            assert.equal(address2, player1)
        })

    })

})