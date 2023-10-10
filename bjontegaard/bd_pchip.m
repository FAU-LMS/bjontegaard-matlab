function [bdrate, IoU]  = bd_pchip(rateA, distA, rateB, distB, plotRCD)
% bd_pchip(rateA, distA, rateB, distB, plotRCD)
% Bjontegaard-Delta Rate calculation. Input is a reference (A) and a test
% (B) performance. At least 2 supporting points are needed. Output is a
% relative rate-distance (percentage obtained by mutliplying with 100). 
% Interpolation method is PCHIP. plotRCD is an optional
% input. If plotRCD==true, a relative difference curve is plotted. IoU is
% the relative intersection over union / overlap of the two curves in the
% dist-domain. A warning is displayed if the IoU is smaller than 75%. 

% BSD 3-Clause License
%
% Copyright (c) 2022-2023, Friedrich-Alexander-Universität Erlangen-Nürnberg.
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
%
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution.
%
% * Neither the name of the copyright holder nor the names of its
%   contributors may be used to endorse or promote products derived from
%   this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if nargin == 4
    plotRCD = false;
end


    minDist = max(min(distA), min(distB));
    maxDist = min(max(distA), max(distB));
 
    % Calculate IoU
    IoU = (maxDist - minDist) / (max(max(distA), max(distB)) - min(min(distA), min(distB)));
    if IoU < 0.75
        disp(['WARNING: Overlap/intersection over union of curves at ' num2str(100*IoU) '%']);
    end

    % Code to plot relative curve differences (RCD)
    if plotRCD
        figure;
        subplot(1,2,1);
        semilogx(rateA, distA, 'LineStyle','none', 'Marker', 'x', 'Color', [1,0,0], 'LineWidth', 1.5);
        hold on;
        semilogx(rateB, distB, 'LineStyle','none', 'Marker', 'o', 'Color', [0,0.8,0], 'LineWidth', 1.5);
        legend({'RD A', 'RD B'}, 'Location','southeast', 'AutoUpdate','off');
        upper = max(max(distA), max(distB));
        lower = min(min(distA), min(distB));
        suppPoints = [lower:(upper-lower)/1000:upper distA distB];
        suppPoints = sort(suppPoints);
        % Remove duplicate entries
        suppPoints = unique(suppPoints(:).');
        grid on;
    else
        suppPoints =  [];
    end
    
    % Interpolate and integrate points for A and B
    [intA, interpRatesA] = bdrint(rateA, distA, minDist, maxDist, suppPoints); % suppPoints only used for RCD plot
    [intB, interpRatesB] = bdrint(rateB, distB, minDist, maxDist, suppPoints);

    avg = (intB - intA) / (maxDist - minDist);
    
    bdrate = (10^avg) - 1;
    
    if plotRCD
        relDifference = 100*(10.^(interpRatesB-interpRatesA)-1);
        yl = ylim;
        subplot(1,2,2);
        idcsA = logical(0*relDifference);
        suppPoints = suppPoints(suppPoints>=minDist & suppPoints<=maxDist);
        for i = 1:length(distA)
            idcsA(suppPoints==distA(i)) = 1;
        end
        idcsB = logical(0*relDifference);
        for i = 1:length(distB)
            idcsB(suppPoints==distB(i)) = 1;
        end
        plot(relDifference(idcsA), suppPoints(idcsA), 'LineStyle','none', 'Marker', 'x', 'Color', [1,0,0], 'LineWidth', 1.5);
        hold on;
        plot(relDifference(idcsB), suppPoints(idcsB), 'LineStyle','none', 'Marker', 'o', 'Color', [0,.8,0], 'LineWidth', 1.5);
        plot(relDifference, suppPoints(suppPoints>=minDist&suppPoints<=maxDist), 'Color', [0,0,0]);
        plot([100*bdrate 100*bdrate], yl, 'LineStyle', '--', 'Color', [0,0,1]);
        legend({'Points A', 'Points B', 'RCD', 'BD-Rate'}, 'Location','southeast', 'AutoUpdate','off');       
        ylim(yl);
        xlabel('Relative Rate Difference (%)');
        ylabel('PSNR');
        grid on;
    end
    
    
end


function [bdrint, ratesOut] = bdrint(rate, dist, low, high, suppPoints)

    nPoints = length(rate);

    for i=1:nPoints
        log_rate(i) = log10(rate(nPoints+1 - i));
        log_dist(i) = dist(nPoints+1 - i);
    end

    
    for i=1:nPoints-1
        H(i) = log_dist(i + 1) - log_dist(i);
        delta(i) = (log_rate(i + 1) - log_rate(i)) / H(i);
    end
    
   % PCHIP determination of derivatives
    d = zeros(nPoints,1);
    if nPoints == 2 % Revert to linear interpolation
        d(:) = delta;
    else
        d(1) = pchipend(H(1), H(2), delta(1), delta(2));
    
        for i=2:nPoints-1
            d(i) = (3 * H(i - 1) + 3 * H(i)) / ((2 * H(i) + H(i - 1)) / delta(i - 1) + (H(i) + 2 * H(i - 1)) / delta(i)); % (5) from " METHOD FOR CONSTRUCTING LOCAL MONOTONE PIECEWISE CUBIC INTERPOLANTS", https://epubs.siam.org/doi/pdf/10.1137/0905021
        end
    
        d(nPoints) = pchipend(H(nPoints-1), H(nPoints-2), delta(nPoints-1), delta(nPoints-2)); % d contains the resulting slopes at positions 1:4
    end
    %% End of PCHIP determination of derivatives
    
    
    for i=1:nPoints-1 % Determine polynomial coefficients from derivatives
        c(i) = (3 * delta(i) - 2 * d(i) - d(i + 1)) / H(i);
        b(i) = (d(i) - 2 * delta(i) + d(i + 1)) / (H(i) * H(i));
    end

    %%%% Information on target cubic rate function: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % cubic function is rate(i) + s*(d(i) + s*(c(i) + s*(b(i))) where s = x - dist(i)%
    % or rate(i) + s*d(i) + s*s*c(i) + s*s*s*b(i)                                    %
    % primitive is s*rate(i) + s*s*d(i)/2 + s*s*s*c(i)/3 + s*s*s*s*b(i)/4            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    result = 0;
    
    for i=1:nPoints-1 % Iterate over intervals
        s0 = log_dist(i);
        s1 = log_dist(i + 1);
        
        % clip s0 to valid range
        s0 = max(s0, low);
        s0 = min(s0, high);
        
        % clip s1 to valid range
        s1 = max(s1, low);
        s1 = min(s1, high);
                
        s0 = s0 - log_dist(i);
        s1 = s1 - log_dist(i);
        
        if (s1 > s0) % Add up integrated curve
            result = result + (s1 - s0) * log_rate(i); 
            result = result + (s1 * s1 - s0 * s0) * d(i) / 2;
            result = result + (s1 * s1 * s1 - s0 * s0 * s0) * c(i) / 3;
            result = result + (s1 * s1 * s1 * s1 - s0 * s0 * s0 * s0) * b(i) / 4;
        end
    end

    % Calculate rate points for RCD plotting
    ratesOut = [];
    if ~isempty(suppPoints)
        subplot(1,2,1);
        for i=1:nPoints-1
            s0 = log_dist(i);
            s1 = log_dist(i + 1);
            if i==1
                currPoints = suppPoints(suppPoints>=s0&suppPoints<=s1);
            else
                currPoints = suppPoints(suppPoints>s0&suppPoints<=s1);
            end
            interpRates = log_rate(i) + (currPoints-s0).*d(i) + c(i)*(currPoints-s0).^2 + b(i)*(currPoints-s0).^3;
            plot(10.^interpRates, currPoints, 'Color', [0,0,0]);   
            ratesOut = [ratesOut interpRates];
        end
        suppPoints = suppPoints(suppPoints >= min(log_dist) & suppPoints <= max(log_dist)); % In the current valid area
        ratesOut = ratesOut(suppPoints>=low & suppPoints<=high);
        xlabel('Rate');
        ylabel('PSNR');
        title('PCHIP');
    end

    
    bdrint = result;
end

function pchipend= pchipend(h1, h2, del1, del2)
    % Boundary handling for derivatives    
    d = ((2 * h1 + h2) * del1 - h1 * del2) / (h1 + h2);
    if (d * del1 < 0)
        d = 0;
    elseif ((del1 * del2 < 0) && (abs(d) > abs(3 * del1)))        
        d = 3 * del1;
    end
    
    pchipend = d;
end