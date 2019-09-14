clearvars; clc; close all
%% Set channels for gating
channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'; 'BL2-H', 'FSC-H'};
channels2scale = {'linear', 'linear'; 'linear', 'linear'; 'log', 'linear'};

%%
data01 = loadfcs();
data02 = loadfcs();
data = [data01, data02];
gate = drawGate(channels2gate, channels2scale);
data = addGate(data,gate);
data = formatfcsdat(data);

%% Add labels to data for plotting
data.label01 = strcat(data.sample,'_',data.replicate);
data.label02 = strcat(data.sample,'_',data.time);
data.nesnls = string(regexp(data.mutant,'(\w*\|\w*)','match','once'));
data.zf = string(regexp(data.mutant,'(?<=\w*\|\w*\|)\w*','match','once'));

% regexp(x,'(?<NES>\w*)\|(?<NLS>\w*)\|(?<ZF>\w*)','names','ignorecase')
%% Remove samples with very low cell counts
% cellcountfinal = varfun(@sum,dataPlot,'InputVariables','Gate_net','GroupingVariables','label');
% deletelist = cellcountfinal(cellcountfinal.sum_Gate_net<1000,:).label;
% idx = find(contains(dataPlot.label,deletelist));
% dataPlot(idx,:) = [];
%% Plot mCitrine expression for each mutant +/-LINuS +/-light
mutantlist = unique(data.mutant,'stable');
loc = reshape(1:15,5,3)';

close all
for n = 1:numel(mutantlist)
    mutant = mutantlist{n};
    dataplot= data(data.mutant==mutant,:);
    dataplot.light(dataplot.time== "0") = "-light";
    dataplot.light(dataplot.time== "2") = "+light";
    [i, j] = find(loc==n);
    
    g(i,j) = gramm('x',log(dataplot.BL2H),'color',cellstr(dataplot.light),...
        'subset', dataplot.BL2H>0 & dataplot.Gate_net==1 & dataplot.reporter=="pCTT1-mCitrine");
    g(i,j).facet_grid(cellstr(dataplot.linus),[],'scale','free_y');
    g(i,j).stat_bin('geom','line','normalization','probability','nbins',100);
    g(i,j).set_title(mutant);
    
    if mutant~="None"
        g(i,j).no_legend();
    end
end

g.set_order_options('row',{'-LINuS','+LINuS'},'color',{'-light','+light'});
g.set_text_options('facet_scaling',0.75,'title_scaling',0.75);
g.set_names('x','log(mCitrine)','y','%','row','');
g.set_title('mCitrine expression')
g.axe_property('XLim',[4 12]);
figure('Position',[100 100 600 600]);
g.draw();

%% Plot mCitrine expression between ZF-WT/A
nesnlslist = unique(data.nesnls(~ismissing(data.nesnls)),'stable');
nesnlslist(nesnlslist=="E|4E") = [];
loc = reshape(1:6,3,2)';

close all
clear g
for n = 1:numel(nesnlslist)
    nesnls = string(nesnlslist{n});
    dataplot = data(data.nesnls==nesnls,:);
    [i, j] = find(loc==n);
    
    g(i,j) = gramm('x',log(dataplot.BL2H),'color',cellstr(dataplot.zf),'linestyle',cellstr(dataplot.time),...
        'subset', dataplot.BL2H>0 & dataplot.Gate_net==1 & dataplot.reporter=="pCTT1-mCitrine" & dataplot.linus=="+LINuS");
    g(i,j).stat_bin('geom','line','normalization','probability','nbins',100);
    g(i,j).set_title([nesnls]);
    
    if n~=numel(nesnlslist)
        g(i,j).no_legend()
    else
        g(i,j).set_layout_options('legend_position',[0.93 0.27 0.15 0.15])
    end
    
    
end

g.set_names('x','log(mCitrine)','y','%','color','ZF','linestyle','Time');
g.set_title('mCitrine expression (+LINuS)');
% g.axe_property('XLim',[4 12]);
figure('Position',[100 100 600 600]);
g.draw();

%% Plot mScarlet
mutantlist = unique(data.mutant,'stable');
mutantlist(mutantlist=="None") = [];
loc = reshape(1:15,5,3)';

close all
for n = 1:numel(mutantlist)
    mutant = mutantlist{n};
    dataplot= data(data.mutant==mutant,:);

    [i, j] = find(loc==n);
    
    g(i,j) = gramm('x',log(dataplot.YL2H),'color',cellstr(dataplot.linus),...
        'subset', dataplot.YL2H>0 & dataplot.Gate_net==1 & dataplot.reporter=="pCTT1-mCitrine");
    g(i,j).stat_bin('geom','line','normalization','probability','nbins',100);
    g(i,j).set_title(mutant);

    if n~=numel(mutantlist)
        g(i,j).no_legend();
    else
        g(i,j).set_layout_options('legend_position',[0.7 0.1 0.15 0.15]);
    end
end

g.set_names('x','log(mScarlet)','y','%');
g.set_title('mScarlet expression');
g.axe_property('XLim',[2 8]);
figure('Position',[100 100 600 600]);
g.draw();
