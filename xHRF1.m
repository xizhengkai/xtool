function  xHRF1(job)


%%
outdir = spm_file(job.odir{1},'cpath');
if ~exist(outdir,'dir')
    sts = mkdir(outdir);
    if ~sts, error('Error creating output directory "%s".',outdir); end
end


TR = job.RT;
weight = job.weight;
lw = length(weight);
totalrun = numel(job.sess);
sess = job.sess;
filename = char(sess(1).scans{:});
[img,~] = wfMRIReadImg(filename(1,:));

%load mask
%-----------------------------------------------------------------------
design_only = ~isempty(job.mask{1});
if design_only
    mask = job.mask{1};
    [roi,~] = wfMRIReadImg(mask);
    roi = roi(:);
else
    roi = img(:) > mean(img(:))/4;
end
%------------------------------------------------------------------------
if(isfield(job.base,'whole_mean'))
    base = 1;
elseif(isfield(job.base,'specify'))
    base = 2;
    basevector = job.base.specify;
elseif(isfield(job.base,'none'))
    base = 3;
end


%%
Nbetaname = 0;
for Nrun = 1 : totalrun
    filename = char(sess(Nrun).scans{:});
    [img,vol] = wfMRIReadImg(filename(1,:));
    [m,n,l] = size(img);
    Nvolumes = length(filename);
    voxel_4D = zeros(Nvolumes,m*n*l);
    for Nv = 1 : Nvolumes
        [img,~] = wfMRIReadImg(filename(Nv,:));
        voxel_4D(Nv,:) = img(:)';
    end
    
    %-Multiple conditions (structure from a MAT-file)
    %----------------------------------------------------------------------
    if ~isempty(sess(Nrun).multi{1})
        
        %-Load MAT-file
        %------------------------------------------------------------------
        try
            multicond = load(sess(Nrun).multi{1});
        catch
            error('Cannot load %s',sess(Nrun).multi{1});
        end
        
        %-Check structure content
        %------------------------------------------------------------------
        if ~all(isfield(multicond, {'names','onsets','durations'})) || ...
                ~iscell(multicond.names) || ...
                ~iscell(multicond.onsets) || ...
                ~iscell(multicond.durations) || ...
                ~isequal(numel(multicond.names), numel(multicond.onsets), ...
                numel(multicond.durations))
            error(['Multiple conditions MAT-file ''%s'' is invalid:\n',...
                'File must contain names, onsets, and durations '...
                'cell arrays of equal length.\n'],sess.multi{1});
        end
        
        for jo=1:numel(multicond.onsets)
            
            %-Mutiple Conditions: names, onsets and durations
            %--------------------------------------------------------------
            cond.name     = multicond.names{jo};
            if isempty(cond.name)
                error('MultiCond file: sess %d cond %d has no name.',Nrun,jo);
            end
            cond.onset    = multicond.onsets{jo};
            if isempty(cond.onset)
                error('MultiCond file: sess %d cond %d has no onset.',Nrun,jo);
            end
            cond.duration = multicond.durations{jo};
            if isempty(cond.onset)
                error('MultiCond file: sess %d cond %d has no duration.',Nrun,jo);
            end
        end
        Cond.name = multicond.names;
        Cond.ons  = multicond.onsets;
        Cond.dur  = multicond.durations;
    else
        %-Condition: name, onset and duration
        %--------------------------------------------------------------
        Cond.name = {sess(Nrun).cond.name};
        Cond.ons  = {sess(Nrun).cond.onset};
        Cond.dur  = {sess(Nrun).cond.duration};
        if numel(Cond.dur) ~= numel(Cond.ons)
            error('Mismatch between number of onset and number of durations.');
        end
    end
    
    hpf = sess(Nrun).hpf;
    to = 2*Nvolumes*TR/hpf + 1;
    to = floor(to);
    TotalConds = numel(Cond.name);
    beta = nan(TotalConds,m*n*l);
    voxel = voxel_4D(:,roi==1);
    voxel = wdetrend(voxel,to,'dct',1);
    fprintf('Calculating run%d\n',Nrun)
    flags = sprintf('Calculating run%d',Nrun);
    q = size(voxel,2);
    spm_progress_bar('Init',totalrun,flags);
    if(base == 1)
        Base = mean(voxel);
        if(Base == 0)
            continue;
        end
        voxel = bsxfun(@rdivide,voxel-Base,Base);
    elseif(base == 2)
        Base = mean(voxel(basevector,:));
        if(Base == 0)
            continue;
        end
        voxel = bsxfun(@rdivide,voxel-Base,Base);
    end
    for Ncon = 1 : TotalConds
        NCurOnset = numel(Cond.ons{Ncon});
        cbeta = nan(NCurOnset,q);
        for Non = 1 : NCurOnset
            Co = round((Cond.ons{Ncon}(Non))/TR)+1;
            b = weight*(voxel(Co:(Co+lw-1),1));
            cbeta(Non,:) = b;
        end
        beta(Ncon,roi==1) = mean(cbeta);
    end
    
    spm_progress_bar('Set',Nrun)
    
    beta = reshape(beta',m,n,l,[]);
    for ona = 1 : TotalConds
        filename = fullfile(outdir,sprintf('beta_%04d.nii',ona+Nbetaname));
        Obeta = beta(:,:,:,ona);
        wfMRIWriteImg(filename,Obeta,vol,'float32')
    end
    fprintf('Run%d has been finished\n',Nrun)
    Nbetaname = Nbetaname + cntb - 1;
end
spm_progress_bar('Clear');
