function [obj]=plotUnwrappedPhases(obj)
%check that input data is valid
if obj.nCh~=2
    obj.hPlot=[];hText=[];
    msgbox('Phase Sync used only for 2 channels');
    return;
end
Fs = 1/(obj.T(2)-obj.T(1))*1000;
V1 = squeeze(obj.M(1,:,:))';
V2 = squeeze(obj.M(2,:,:))';
VF1=butterFilter(V1,Fs,obj.plotParams.lowcutoff,obj.plotParams.highcutoff,obj.plotParams.order);
VF2=butterFilter(V2,Fs,obj.plotParams.lowcutoff,obj.plotParams.highcutoff,obj.plotParams.order);

H1=hilbert(VF1); H2=hilbert(VF2);

phase1 = angle(H1)'; phase2 = angle(H2)';
phaseDiff = phase2 - phase1;

uphase1 = unwrap(phase1); uphase2 = unwrap(phase2);
unwrapPhaseDiff = uphase2 - uphase1;

% ananlyticPhaseDiff = atan2(imag(H1').*real(H2') - real(H1').*imag(H2'),...
%                            real(H1').*real(H2') + imag(H1').*imag(H2'));
% ananlyticPhaseDiff = unwrap(ananlyticPhaseDiff);
ananlyticPhaseDiff = sqrt((real(H1')-real(H2')).^2 + (imag(H1')-imag(H2')).^2);
                       
obj.hPlot=plot(obj.hPlotAxis,...
    obj.T,phase1,obj.T,phase2);

verticalShift = 2;
scaleV = 4;
plots = {phaseDiff, ananlyticPhaseDiff, V2/scaleV, V1/scaleV}; %unwrapPhaseDiff
maxY = max([phase1 phase2]);
for j=1:length(plots)
    dy = abs(min(plots{j})) + maxY + verticalShift;
    y = plots{j} + dy;
    p = plot(obj.T, y,'Parent',obj.hPlotAxis);
    l = line([obj.T(1),obj.T(end)],[dy,dy],'Parent',obj.hPlotAxis);
    obj.hPlot=[obj.hPlot;p;l];
    maxY = max(y);
end

obj.hPlotAxis.ColorOrderIndex=1;
ylim(obj.hPlotAxis, [-7 maxY])
% leg = legend({'Phase1', 'Phase2','phaseDiff','ananlyticPhaseDiff',...
%     'unwrapPhaseDiff', 'V2', 'V1'}, 'Parent',obj.hPlotAxis);
hText = text(4, -5, ['Shanon Entropy Index: ',...
    num2str(shanonEntropyIndex(phase1,phase2))],...
    'Parent',obj.hPlotAxis,'FontSize',12,'FontWeight','Bold','BackgroundColor','w');

obj.hPlot=[obj.hPlot;hText];
% obj.hPlot=[obj.hPlot;leg];
% 
% f = figure(1);
% parent = obj.hPlotAxis.Parent;
% set(gcf, 'Position', f.Position);
% 
% h1 = subplot(2,1,1);
% plot(h1, obj.T, VF{1}{1}, obj.T, VF{1}{2}); 
% ylim(h1, [min(VF{1}{2}) max(VF{1}{2})]);
% h1.ColorOrderIndex=1;
% 
% h2 = subplot(2,1,2);
% plot(h2,obj.T, phase1, obj.T, phase2);
% ylim(h2, [min(phase1) max(phase1)]);
% h2.ColorOrderIndex=1;
% 
% f1 = gcf;
% compCopy(f1,f);
% clf
% 
% function compCopy(op, np)
% %COMPCOPY copies a figure object represented by "op" and its % descendants to another figure "np" preserving the same hierarchy.
% ch = get(op, 'children');
% if ~isempty(ch)
% nh = copyobj(ch,np);
% for k = 1:length(ch)
% compCopy(ch(k),nh(k));
% end
% end
% return
% ax1Chil = ax1.Children; 
% % Copy all ax1 objects to axis 2
% copyobj(ax1Chil, obj.hPlotAxis)

% nRow=ceil(sqrt(obj.nCh*obj.nTrials));
% nCol=ceil(obj.nCh*obj.nTrials/nRow);
% P=cell(nRow,nCol);h
% %selection of input data
% if obj.nCh==1 && obj.nTrials>1
%     for i=1:obj.nCh
%         [~,F,T,Ptmp]=spectrogram(squeeze(obj.M(1,i,:)),obj.plotParams.window*Fs/1000,obj.plotParams.overlap*Fs/1000,obj.plotParams.NFFT,Fs);
%         P{i}=Ptmp(1:obj.plotParams.maxFreq,:);
%     end
% elseif obj.nCh>1 && obj.nTrials==1
%     for i=1:obj.nCh
%         [~,F,T,Ptmp]=spectrogram(squeeze(obj.M(i,1,:)),obj.plotParams.window*Fs/1000,obj.plotParams.overlap*Fs/1000,obj.plotParams.NFFT,Fs);
%         P{i}=Ptmp(1:obj.plotParams.maxFreq,:);
%     end
% elseif obj.nCh==1 && obj.nTrials==1
%     i=1;
%     [~,F,T,Ptmp]=spectrogram(squeeze(obj.M(1,1,:)),round(obj.plotParams.window*Fs/1000),round(obj.plotParams.overlap*Fs/1000),obj.plotParams.NFFT,Fs);
%     P{i}=Ptmp(1:obj.plotParams.maxFreq,:);
% end
% %initialize combined data matrix
% [nFreq nTimes]=size(P{1});
% P(i+1:end)={nan([nFreq nTimes])};
% 
% M=cell2mat(P);
% dT=(T(2)-T(1))*1000;
% dF=F(2)-F(1);
% %obj.hPlot=surf(repmat(T,[1 nCol]),repmat(F,[nRow 1])',10*log10(abs(M)+eps),'EdgeColor','none');view(0,90);
% %obj.hPlot=surf(10*log10(abs(M)+eps),'EdgeColor','none');view(0,90);
% obj.hPlot=imagesc(dT/2:dT:(dT*nCol*nTimes),dF/2:dF:(dF*nRow*nFreq),10*log10(M+eps),'Parent',obj.hPlotAxis);
% 
% [X,Y]=meshgrid(1:nRow,1:nCol);
% 
% if obj.nTrials==1
%     hText=text((X(1:obj.nCh)*nTimes-nTimes+1)*dT,(Y(1:obj.nCh)*nFreq-nFreq/8)*dF,num2cell(obj.channelNumbers),...
%         'Parent',obj.hPlotAxis,'FontSize',6,'FontWeight','Bold');
% elseif obj.nCh==1
%     hText=text((X(1:obj.nCh)*nTimes-nTimes+1)*dT,(Y(1:obj.nCh)*nFreq-nFreq/8)*dF,num2cell(1:obj.nTrials),...
%         'Parent',obj.hPlotAxis,'FontSize',6,'FontWeight','Bold');
% end
% 
% hLines=line([([X(1,1:end-1);X(1,1:end-1)])*dT*nTimes [zeros(1,nCol-1);ones(1,nCol-1)*dT*nCol*nTimes]],...
%     [[zeros(1,nRow-1);ones(1,nRow-1)*dF*nRow*nFreq] ([Y(1:end-1,1) Y(1:end-1,1)])'*dF*nFreq],...
%     'color','k','Parent',obj.hPlotAxis);
% 
% xlim(obj.hPlotAxis,[0 (dT*nCol*nTimes)]);
% ylim(obj.hPlotAxis,[0 (dF*nRow*nFreq)]);
% xlabel(obj.hPlotAxis,'Time [ms]');
% ylabel(obj.hPlotAxis,'Frequency [Hz]');
%  
% set(obj.hPlotControls.spectrogramData,'string',{['T=' num2str(dT,5) ' - ' num2str(T(end)*1000,5)],['F=' num2str(dF,5) ' - ' num2str(F(nFreq),5)]},'FontSize',8);
% 
% [hScaleBar]=addScaleBar(obj.hPlotAxis,'YUnitStr','Freq','YUnitStr','Hz');
% obj.hPlot=[obj.hPlot;hText;hLines;hScaleBar];