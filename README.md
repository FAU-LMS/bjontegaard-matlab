[![License](https://img.shields.io/badge/license-BSD%203--Clause-green)](https://opensource.org/licenses/BSD-3-Clause)
![GitHub top language](https://img.shields.io/github/languages/top/FAU-LMS/bjontegaard-matlab)

# Bjøntegaard-Delta Interpolation

BD-rate implementations in Matlab. Also available in [Python](https://github.com/FAU-LMS/bjontegaard).

## Introduction
The Bjøntegaard-Delta (BD) metrics (delta bit rate and delta PSNR) described in [1] are well known metrics to measure the average differences between two rate-distortion (RD) curves. They are based on **cubic-spline interpolation (CSI)** of the RD curves and [Matlab](https://www.mathworks.com/matlabcentral/fileexchange/41749-bjontegaard-metric-calculation-bd-psnr) as well as [Python](https://github.com/google/compare-codecs/blob/master/lib/visual_metrics.py) implementations are available on the internet.

However, this way of interpolation using a third-order polynomial leads to problems for certain RD curve constellations and causes very misleading results.
This has also been experienced during the standardization of HEVC.
Consequently, the so-called **piecewise cubic hermite interpolation (PCHIP)** has been implemented in the JCT-VC Common Test Conditions (CTC) Excel sheet [[2]](http://phenix.int-evry.fr/jct/doc_end_user/documents/12_Geneva/wg11/JCTVC-L1100-v1.zip) for performance evaluation. In further studies [[4]](https://doi.org/10.48550/arXiv.2202.12565) - [[5]](https://arxiv.org/abs/2304.12852), it was found that **Akima interpolation** returns more accurate and stable results. An example for corresponding interpolated curves is shown below.

This page provides BD-rate implementations ([see here for a Python implementation](https://github.com/FAU-LMS/bjontegaard)) for both PCHIP and Akima interpolation in Matlab.
In our tests, the implementation of PCHIP returns the same value as the Excel-Implementation from [[3]](https://jvet-experts.org/doc_end_user/documents/20_Teleconference/wg11/JVET-T2010-v2.zip) with an accuracy of at least 10 decimal positions. 
The scripts allow to calculate the BD for any number of RD points greater one.


## Usage

Use the ```example_usage.m``` for testing. 

Basic example with test data measured using ffmpeg (libx265 with different preset settings) and Akima interpolation:
```Matlab

# Test data
rate_anchor = [9487.76, 4593.60, 2486.44, 1358.24];
psnr_anchor = [ 40.037,  38.615,  36.845,  34.851];
rate_test = [9787.80, 4469.00, 2451.52, 1356.24];
psnr_test = [ 40.121,  38.651,  36.970,  34.987];

# Call calculation
bdr_akima = bd_akima(rate_anchor, psnr_anchor, rate_test, psnr_test);

disp(['Akima BDR: ' num2str(bdr_akima*100,'%4.16f') '%']);
```

The parameters `rate_anchor` and `dist_anchor` describe the rate-distortion points of the anchor, `rate_test` and `dist_test` describe the rate-distortion points of the test codec.

Available interpolation methods:
* `'bd_pchip.m'`: Piecewise cubic hermite interpolation (used in standardizations [[2]](http://phenix.int-evry.fr/jct/doc_end_user/documents/12_Geneva/wg11/JCTVC-L1100-v1.zip), [[3]]((https://jvet-experts.org/doc_end_user/documents/20_Teleconference/wg11/JVET-T2010-v2.zip)))
* `'bd_akima.m'`: Akima interpolation [[4]](https://doi.org/10.48550/arXiv.2202.12565)

## Relative curve difference plots (RCD-plots)

For in-depth evaluation of codec comparison results, we recommend to take relative curve difference plots (RCD-plots) into account (see [[5]](https://arxiv.org/abs/2304.12852)).
They can be created using:
* `bdr_akima = bd_akima(rate_anchor, psnr_anchor, rate_test, psnr_test, true);`

Here is an example for a RCD plot. 

![Relative curve difference](https://github.com/FAU-LMS/bjontegaard-matlab/blob/main/doc/rcd.png)

The left plot shows the supporting points and the Akima-interpolated curves for both anchor and test. The right plot shows the relative horizontal difference between the two curves in percentage. 

## Comparison between interpolation methods

Furthermore, a comparison between the interpolated curves and intermediate, true rate-distortion points between the supporting points is shown in the plot below. 
For this example, the quality is represented by the SSIM value. Note that the example was cherry-picked to show that cubic interpolation can fail. The curve interpolated by the Akima interpolator is closest to the intermediate points. 

![Measured data](https://raw.githubusercontent.com/FAU-LMS/bjontegaard/main/doc/interpolated_curves.png)

## References
[1] G. Bjontegaard, "Calculation of average PSNR differences between RD-curves", VCEG-M33, Austin, TX, USA, April 2001. <br/>
[2] F. Bossen, "Common HM test conditions and software reference configurations", JCTVC-L1100, Geneva, Switzerland, April 2013. <br/>
[3] F. Bossen, "VTM common test conditions and software reference configurations for SDR video", JVET-T2020, Teleconference, October 2020. <br/>
[4] C. Herglotz, M. Kränzler, R. Mons, A. Kaup, "Beyond Bjontegaard: Limits of Video Compression Performance Comparisons", Proc. International Conference on Image Processing (ICIP) 2022, [online](https://doi.org/10.48550/arXiv.2202.12565) available. <br/>
[5] C. Herglotz, H. Och, A. Meyer, G. Ramasubbu, L. Eichermüller, M. Kränzler, F. Brand, K. Fischer, D. T. Nguyen, A. Regensky, and A. Kaup, “The Bjøntegaard Bible – Why Your Way of Comparing Video Codecs May Be Wrong,” IEEE Transactions on Image Processing, 2024, [online]([https://doi.org/10.48550/arXiv.2202.12565](https://arxiv.org/abs/2304.12852)) available.

## License

BSD 3-Clause. For details, see [LICENSE](https://github.com/FAU-LMS/bjontegaard/blob/main/LICENSE).
