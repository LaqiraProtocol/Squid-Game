const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai')


const SquidGame = artifacts.require('SquidGame')
const ERC20TokenMock = artifacts.require('ERC20TokenMock')

contract('SquidGame', function (accounts) {
    const [owner, player1, plyaer2, player3] = accounts
    const fee = '10000000000000000'
    const requiredAmount = '1000000000000000000'
    const initialSupply = '10000000000000000000'

    const rank = '1'
    const prize = '10000000000000000000'


    beforeEach(async function () {1
        this.LaqiraToken = await ERC20TokenMock.new('LaqiraTokenMock', 'LQR', initialSupply, {from: owner})
        this.SquidToken = await ERC20TokenMock.new('SquidGameTokenMock', 'SQUID', initialSupply, {from: owner})
        
        this.SquidGameContract = await SquidGame.new(this.LaqiraToken.address, this.SquidToken.address)
    })

    it('Laqira Token', async function () {
        expect(await this.SquidGameContract.laqiraToken()).to.be.bignumber.equal(this.SquidToken.address)
    })

    it('setFee', async function () {
        await this.SquidGameContract.setFee(fee)
        expect(await this.SquidGameContract.fee()).to.be.bignumber.equal(fee) 
    })

    it('requiredAmount', async function () {
        await this.SquidGameContract.setTokenAmount(requiredAmount)
        expect(await this.SquidGameContract.getRequiredAmount()).to.be.bignumber.equal(requiredAmount) 
    })
    
    describe('register participant', function () {
        it('success registration', async function () {
            await this.LaqiraToken.transfer(player1, requiredAmount, {from: owner})
            await this.SquidToken.transfer(player1, requiredAmount, {from: owner})

            await this.SquidGameContract.setTokenAmount(requiredAmount)
            expect(await this.SquidGameContract.getRequiredAmount()).to.be.bignumber.equal(requiredAmount)

            await this.SquidGameContract.setFee(fee)
            expect(await this.SquidGameContract.fee()).to.be.bignumber.equal(fee)

            await this.SquidGameContract.register({from: player1, value: fee})

            expect(await this.SquidGameContract.isParticipant(player1)).to.be.true
            expect(await this.SquidGameContract.getRegisterdParticipants()).to.be.bignumber.equal('1')
        })

        it('Insufficient SQUID token balance', async function () {
            await this.LaqiraToken.transfer(player1, requiredAmount, {from: owner})

            await this.SquidGameContract.setTokenAmount(requiredAmount)

            await expectRevert(this.SquidGameContract.register({from: player1, value: fee}), 'Insufficient SQUID balance')
        })

        it('Insufficient LQR token balance', async function () {
            await this.SquidToken.transfer(player1, requiredAmount, {from: owner})

            await this.SquidGameContract.setTokenAmount(requiredAmount)

            await expectRevert(this.SquidGameContract.register({from: player1, value: fee}), 'Insufficient LQR balance')
        })

        it('Insufficient registration fee', async function () {
            await this.LaqiraToken.transfer(player1, requiredAmount, {from: owner})
            await this.SquidToken.transfer(player1, requiredAmount, {from: owner})
            await this.SquidGameContract.setTokenAmount(requiredAmount)
            await this.SquidGameContract.setFee(fee)
            await expectRevert(this.SquidGameContract.register({from: player1, value: '1000000000000000'}), 'Insufficient fund for registration')
        })

        it('Participant already exists', async function () {
            await this.LaqiraToken.transfer(player1, requiredAmount, {from: owner})
            await this.SquidToken.transfer(player1, requiredAmount, {from: owner})

            await this.SquidGameContract.setTokenAmount(requiredAmount)

            await this.SquidGameContract.setFee(fee)

            // First run
            await this.SquidGameContract.register({from: player1, value: fee})            

            // Second run
            await expectRevert(this.SquidGameContract.register({from: player1, value: fee}), 'Participant already exists')
        })


        it('Finished registration', async function () {
            await this.SquidGameContract.setFinished()
            expect(await this.SquidGameContract.finishedStatus()).to.be.true
            await expectRevert(this.SquidGameContract.register({from: player1, value: fee}), 'Registration period has ended')
        })
    })
    
    describe('Stages', function () {
        describe('stage1', function () {
            it('Stage1', async function () {
                await this.SquidGameContract.register({from: player1})              
                await this.SquidGameContract.setStage1Pass(player1, {from: owner})
                expect(await this.SquidGameContract.isParticipant(player1)).to.be.true
            })
    
            it('Unregistered', async function () {
                await expectRevert(this.SquidGameContract.setStage1Pass(player1, {from: owner}), 'Given address has not registered')
                expect(await this.SquidGameContract.isParticipant(player1)).to.be.false
            })
    
            it('onlyOwner', async function () {
                await expectRevert(this.SquidGameContract.setStage1Pass(player1, {from: player1}), 'Ownable: caller is not the owner')
            })    
        })

        describe('Stage2', function () {
            it('Stage2', async function () {
                await this.SquidGameContract.register({from: player1})              
                await this.SquidGameContract.setStage1Pass(player1, {from: owner})

                await this.SquidGameContract.setStage2Pass(player1, {from: owner})
            })

            it('First in stage 1', async function () {
                await this.SquidGameContract.register({from: player1})

                await expectRevert(this.SquidGameContract.setStage2Pass(player1, {from: owner}), 'Stage1: Wrong participant')
            })
            
            it('onlyOwner', async function () {
                await expectRevert(this.SquidGameContract.setStage2Pass(player1, {from: player1}), 'Ownable: caller is not the owner')
            })
        })

        describe('Stage3', function () {
            it('Stage3', async function () {
                await this.SquidGameContract.register({from: player1})              
                await this.SquidGameContract.setStage1Pass(player1, {from: owner})

                await this.SquidGameContract.setStage2Pass(player1, {from: owner})
            
                await this.SquidGameContract.setStage3Pass(player1, {from: owner})
            })

            it('First in stage 2', async function () {
                await this.SquidGameContract.register({from: player1})
                
                await this.SquidGameContract.setStage1Pass(player1, {from: owner})

                await expectRevert(this.SquidGameContract.setStage3Pass(player1, {from: owner}), 'Stage2: Wrong participant')
            })

            it('onlyOwner', async function () {
                await expectRevert(this.SquidGameContract.setStage3Pass(player1, {from: player1}), 'Ownable: caller is not the owner')
            })
        })

        describe('Stage4', function () {
            it('Stage4', async function () {
                await this.SquidGameContract.register({from: player1})
                await this.SquidGameContract.setStage1Pass(player1, {from: owner})

                await this.SquidGameContract.setStage2Pass(player1, {from: owner})
            
                await this.SquidGameContract.setStage3Pass(player1, {from: owner})

                await this.SquidGameContract.setStage4Pass(player1, rank, prize, {from: owner})
            })

            it('First in stage 3', async function () {
                await this.SquidGameContract.register({from: player1})
                
                await this.SquidGameContract.setStage1Pass(player1, {from: owner})

                await this.SquidGameContract.setStage2Pass(player1, {from: owner})

                await expectRevert(this.SquidGameContract.setStage4Pass(player1, rank, prize, {from: owner}), 'Stage3: Wrong participant')
            })

            it('onlyOwner', async function () {
                await expectRevert(this.SquidGameContract.setStage4Pass(player1, rank, prize, {from: player1}), 'Ownable: caller is not the owner')
            })
        })


    })
})