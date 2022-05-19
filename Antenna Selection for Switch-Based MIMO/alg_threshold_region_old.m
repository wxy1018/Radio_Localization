% author: hui.chen@kaust.edu.sa

% ref_doa: in radius
% d: sensor locations in [lambda/2]
% snr: in dB.
% E2 is with probability normalization.
function [Es, CRBs, threshold_snr, V, Vmax] = alg_threshold_region_old(target_doa, ref_doa, d, snrdB)
    
% find beam pattern peaks
    u0 = sin(target_doa/180*pi);
    a0 = exp(-1j*pi*d*u0);  % steering vector
    sigma = 0;  
    tx = 1;         % transmitted signal, single snapshot
    n = sigma*randn(size(a0)) + 1j*sigma*randn(size(a0));   % zero noise
    x = a0*tx+n;
%     doa = -1:0.01:1;
    doa = ref_doa;
    V = zeros(1,length(doa));
    for i = 1:length(doa)
        u = doa(i);
        au = exp(-1j*pi*d*u);
        V(i) = abs(au'*x)^2/(au'*au);
    end
    % figure;plot(doa, V)
    V2 = [0 V 0];   % pad zeros
    diff1 = sign(diff(V2));
    diff2 = diff(diff1);
    Vmax = find(diff2==-2);
    [B, I] = sort(V(Vmax),'descend');
    Vmax = Vmax(I);

% calculate probability and mse 

% approximation of the mse
    K = length(d); % number of sensors
    S = K*(10.^(snrdB/10)); % Array SNR
%     SdB = 10*log10(S);
    Approx1 = zeros(1, length(S));  % expected MSE using method 1
    Approx2 = zeros(1, length(S));

    CRBs = zeros(1, length(S));
    sigma = sqrt(1);
    for snr_i = 1:length(S)
        s = S(snr_i);
        b = sqrt(s*sigma^2/K);  
        M = sum((d-mean(d)).^2);    
        CRB = sigma^2/2/pi^2/b^2/M; % CRLB

        Pns = zeros(1,length(Vmax));
        for i = 1:length(Vmax)
            un = doa(Vmax(i));
            wn = exp(-1j*pi*d*un);
            gn = abs(a0'*wn)/K;
%             if(Vmax(i)==1 || Vmax(i)==length(V))    % compensate edge lobe
%                 gn = gn*(V(1)/K)^2;
%     %             gn = gn*(V(1)/K);
%             end
            I0 = besseli(0,gn*s/2);
            Pn = 1/2*exp(-s/2)*I0;
            Pns(i) = Pn;
        end

        Pns_n = Pns; % normalized probablity.
        if(sum(Pns_n(2:end)) > 1)
            Pns_n = Pns_n/sum(Pns_n);
        end
        Pns_n(1) = 1 + Pns_n(1) - sum(Pns_n);
        Pns(1) = 1 + Pns(1) - sum(Pns);

        E1 = 0;
        E2 = 0;
        for i = 1:length((Vmax))
            un = doa(Vmax(i));
            if(i == 1)
                E1 = E1 + Pns(i)*CRB;   % radius
                E2 = E2 + Pns_n(i)*CRB;   % radius
    %             E = E + Pns(i)*CRB*(180/pi/cos(39.5/180*pi))^2;   % degree
            else
                E1 = E1 + Pns(i)*(u0-un)^2; % radius
                E2 = E2 + Pns_n(i)*(u0-un)^2;   % radius
    %             E = E + Pns(i)*(asin(u0)/pi*180-asin(un)/pi*180)^2;   % degree
            end
        end
        Approx1(snr_i) = E1;
        Approx2(snr_i) = E2;
        CRBs(snr_i) = CRB;
    end

    Approx1 = remove_nan(Approx1, CRBs);
    Approx2 = remove_nan(Approx2, CRBs);

%     Es = [Approx2];
    Es = [Approx1; Approx2];
    diff_snr = 10*log10(Es(1,:)) - 10*log10(CRBs);
    thres_ind = sum(diff_snr>1)+1;
    if thres_ind > length(snrdB)
        threshold_snr = 100;
    else
    	threshold_snr = snrdB(sum(diff_snr>1)+1);
    end
    
%     CRBs
end