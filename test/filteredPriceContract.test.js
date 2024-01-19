// test/filteredPriceContract.test.js
const { expect } = require('chai');
const { ethers } = require('hardhat');
const { BigNumber } = require('ethers');

describe('FilteredPriceContract', function () {
    let filteredPriceContract;
    let owner;

    beforeEach(async () => {
        const FilteredPriceContract = await ethers.getContractFactory('FilteredPriceContract');
        filteredPriceContract = await FilteredPriceContract.deploy();
        await filteredPriceContract.deployed();

        [owner] = await ethers.getSigners();
    });

    it('should deploy with initial values', async function () {
        const result = await filteredPriceContract.kalmanFilteredPrice()
        expect(result.toString()).to.equal("0");
        
        expect(await filteredPriceContract.kalmanQ()).to.equal(1);
        const expectedVariance = '1'; // Expected value as a string
        const actualVariance = (await filteredPriceContract.kalmanVariance()).toString();
        //expect(actualVariance).to.equal(expectedVariance);

        expect(await filteredPriceContract.gaussianMean()).to.equal(0);
        expect(await filteredPriceContract.gaussianVariance()).to.equal(1);
        expect(await filteredPriceContract.gaussianR()).to.equal(0.25);

        expect(await filteredPriceContract.smoothingFactor()).to.equal(0.5);
    });

    it('should calculate filtered price correctly with default values', async function () {
        // Assuming the default values are 0 for Kalman and Gaussian filters
        await filteredPriceContract.updateKalmanFilter(0);
        await filteredPriceContract.updateGaussianFilter(0);

        const result = await filteredPriceContract.calculateFilteredPrice();
        expect(result.toString()).to.equal("0");
    });

    it('should update Kalman filter correctly', async function () {
        await filteredPriceContract.updateKalmanFilter(100);
        const filteredPrice = await filteredPriceContract.kalmanFilteredPrice();
        const variance = await filteredPriceContract.kalmanVariance();

        expect(filteredPrice).to.not.equal(0);
        expect(variance).to.not.equal(1);
    });

    it('should update Gaussian filter correctly', async function () {
        await filteredPriceContract.updateGaussianFilter(150);
        const gaussianMean = await filteredPriceContract.gaussianMean();
        const variance = await filteredPriceContract.gaussianVariance();

        expect(gaussianMean).to.not.equal(0);
        expect(variance).to.not.equal(1);
    });

    it('should calculate filtered price correctly after updating Kalman filter', async function () {
        await filteredPriceContract.updateKalmanFilter(100);
        const result = await filteredPriceContract.calculateFilteredPrice();
        expect(result).to.not.equal(0);
    });

    it('should calculate filtered price correctly after updating Gaussian filter', async function () {
        await filteredPriceContract.updateGaussianFilter(150);
        const result = await filteredPriceContract.calculateFilteredPrice();
        expect(result).to.not.equal(0);
    });

    it('should calculate filtered price correctly after updating both filters', async function () {
        await filteredPriceContract.updateKalmanFilter(100);
        await filteredPriceContract.updateGaussianFilter(150);
        const result = await filteredPriceContract.calculateFilteredPrice();
        // expect(result).to.equal(expectedValue);
    });

    it('should emit FilteredPriceUpdated event when updating Kalman filter', async function () {
        const tx = await filteredPriceContract.updateKalmanFilter(100);
        const receipt = await tx.wait();

        // Check if the event was emitted
        const event = receipt.events.find((e) => e.event === 'FilteredPriceUpdated');
        expect(event).to.not.be.undefined;


        // expect(event.args.newFilteredPrice).to.equal(expectedValue);
    });

    it('should emit FilteredPriceUpdated event when updating Gaussian filter', async function () {
        const tx = await filteredPriceContract.updateGaussianFilter(150);
        const receipt = await tx.wait();

        // Check if the event was emitted
        const event = receipt.events.find((e) => e.event === 'FilteredPriceUpdated');
        expect(event).to.not.be.undefined;

        // Check the emitted values if necessary
        // expect(event.args.newFilteredPrice).to.equal(expectedValue);
    });
});
