function cfg = tbx_cfg_xtool



if ~isdeployed, addpath(fullfile(spm('dir'),'toolbox','xtool')); end



% -------------------------------------------------------------------------
% odir Output Directory
% -------------------------------------------------------------------------
odir         = cfg_files;
odir.tag     = 'odir';
odir.name    = 'Output directory';
odir.help    = {'Select the directory where the beta files should be written.'};
odir.filter = 'dir';
odir.ufilter = '.*';
odir.num     = [1 1];

% -------------------------------------------------------------------------
% mask
% -------------------------------------------------------------------------
mask         = cfg_files;
mask.tag     = 'mask';
mask.name    = 'Mask';
mask.help    = {'Select the mask file or no choose'};
mask.filter = 'nii';
mask.ufilter = '.*';
mask.val{1}    = {''};
mask.num     = [0 1];

%--------------------------------------------------------------------------
% RT Interscan interval
%--------------------------------------------------------------------------
RT         = cfg_entry;
RT.tag     = 'RT';
RT.name    = 'Interscan interval';
RT.help    = {'Interscan interval, TR, (specified in seconds).  This is the time between acquiring a plane of one volume and the same plane in the next volume.  It is assumed to be constant throughout.'};
RT.strtype = 'r';
RT.num     = [1 1];

%--------------------------------------------------------------------------
% mparam
%--------------------------------------------------------------------------
mparam         = cfg_entry;
mparam.tag     = 'weight';
mparam.name    = 'Weight of response';
mparam.val     = {[0 0 0 0 0.2 0.2 0.2 0.2 0.2]};
mparam.help    = {
                  'The weigtht vector of response required for hrf'
}';
mparam.strtype = 'e';
mparam.num     = [1 inf];




%--------------------------------------------------------------------------
% scans Scans
%--------------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Scans';
scans.help    = {'Select the fMRI scans for this session.  They must all have the same image dimensions, orientation, voxel size etc.'};
scans.filter  = {'image','mesh'};
scans.ufilter = '.*';
scans.num     = [1 Inf];

%--------------------------------------------------------------------------
% name Name
%--------------------------------------------------------------------------
name         = cfg_entry;
name.tag     = 'name';
name.name    = 'Name';
name.help    = {'Condition Name'};
name.strtype = 's';
name.num     = [1 Inf];

%--------------------------------------------------------------------------
% onset Onsets
%--------------------------------------------------------------------------
onset         = cfg_entry;
onset.tag     = 'onset';
onset.name    = 'Onsets';
onset.help    = {'Specify a vector of onset times for this condition type. '};
onset.strtype = 'r';
onset.num     = [Inf 1];

%--------------------------------------------------------------------------
% duration Durations
%--------------------------------------------------------------------------
duration         = cfg_entry;
duration.tag     = 'duration';
duration.name    = 'Durations';
duration.help    = {'Specify the event durations. Epoch and event-related responses are modeled in exactly the same way but by specifying their different durations.  Events are specified with a duration of 0.  If you enter a single number for the durations it will be assumed that all trials conform to this duration. If you have multiple different durations, then the number must match the number of onset times.'};
duration.strtype = 'r';
duration.num     = [Inf 1];

%--------------------------------------------------------------------------
% cond Condition
%--------------------------------------------------------------------------
cond         = cfg_branch;
cond.tag     = 'cond';
cond.name    = 'Condition';
cond.val     = {name onset duration };
cond.help    = {'An array of input functions is contructed, specifying occurrence events or epochs (or both). These are convolved with a basis set at a later stage to give regressors that enter into the design matrix. Interactions of evoked responses with some parameter (time or a specified variate) enter at this stage as additional columns in the design matrix with each trial multiplied by the [expansion of the] trial-specific parameter. The 0th order expansion is simply the main effect in the first column.'};

%--------------------------------------------------------------------------
% generic Conditions
%--------------------------------------------------------------------------
generic1         = cfg_repeat;
generic1.tag     = 'generic';
generic1.name    = 'Conditions';
generic1.help    = {'You are allowed to combine both event- and epoch-related responses in the same model and/or regressor. Any number of condition (event or epoch) types can be specified.  Epoch and event-related responses are modeled in exactly the same way by specifying their onsets [in terms of onset times] and their durations.  Events are specified with a duration of 0.  If you enter a single number for the durations it will be assumed that all trials conform to this duration.For factorial designs, one can later associate these experimental conditions with the appropriate levels of experimental factors. '};
generic1.values  = {cond };
generic1.num     = [0 Inf];

%--------------------------------------------------------------------------
% multi Multiple conditions
%--------------------------------------------------------------------------
multi         = cfg_files;
multi.tag     = 'multi';
multi.name    = 'Multiple conditions';
multi.val{1} = {''};
multi.help    = {
                 'Select the *.mat file containing details of your multiple experimental conditions. '
                 ''
                 'If you have multiple conditions then entering the details a condition at a time is very inefficient. This option can be used to load all the required information in one go. You will first need to create a *.mat file containing the relevant information. '
                 ''
                 'This *.mat file must include the following cell arrays (each 1 x n): names, onsets and durations. eg. names=cell(1,5), onsets=cell(1,5), durations=cell(1,5), then names{2}=''SSent-DSpeak'', onsets{2}=[3 5 19 222], durations{2}=[0 0 0 0], contain the required details of the second condition. These cell arrays may be made available by your stimulus delivery program, eg. COGENT. The duration vectors can contain a single entry if the durations are identical for all events. Optionally, a (1 x n) cell array named orth can also be included, with a 1 or 0 for each condition to indicate whether parameteric modulators should be orthogonalised.'
}';
multi.filter = 'mat';
multi.ufilter = '.*';
multi.num     = [0 1];


%--------------------------------------------------------------------------
% hpf High-pass filter
%--------------------------------------------------------------------------
hpf         = cfg_entry;
hpf.tag     = 'hpf';
hpf.name    = 'High-pass filter';
hpf.help    = {'The default high-pass filter cutoff is 128 seconds.Slow signal drifts with a period longer than this will be removed. Use ''explore design'' to ensure this cut-off is not removing too much experimental variance. High-pass filtering is implemented using a residual forming matrix (i.e. it is not a convolution) and is simply to a way to remove confounds without estimating their parameters explicitly.  The constant term is also incorporated into this filter matrix.'};
hpf.strtype = 'r';
hpf.num     = [1 1];
hpf.def     = @(val)spm_get_defaults('stats.fmri.hpf', val{:});

%--------------------------------------------------------------------------
% sess Subject/Session
%--------------------------------------------------------------------------
sess         = cfg_branch;
sess.tag     = 'sess';
sess.name    = 'Subject/Session';
sess.val     = {scans generic1 multi hpf};
sess.help    = {'The design matrix for fMRI data consists of one or more separable, session-specific partitions.  These partitions are usually either one per subject, or one per fMRI scanning session for that subject.'};

%--------------------------------------------------------------------------
% generic Data & Design
%--------------------------------------------------------------------------
generic         = cfg_repeat;
generic.tag     = 'generic';
generic.name    = 'Data & Design';
generic.help    = {
                   'The design matrix defines the experimental design and the nature of hypothesis testing to be implemented.  The design matrix has one row for each scan and one column for each effect or explanatory variable. (e.g. regressor or stimulus function).  '
                   ''
                   'This allows you to build design matrices with separable session-specific partitions.  Each partition may be the same (in which case it is only necessary to specify it once) or different.  Responses can be either event- or epoch related, where the latter model involves prolonged and possibly time-varying responses to state-related changes in experimental conditions.  Event-related response are modelled in terms of responses to instantaneous events.  Mathematically they are both modelled by convolving a series of delta (stick) or box-car functions, encoding the input or stimulus function. with a set of hemodynamic basis functions.'
}';
generic.values  = {sess };
generic.num     = [1 Inf];

%--------------------------------------------------------------------------
%Whole_mean
%--------------------------------------------------------------------------
Whole_mean         = cfg_const;
Whole_mean.tag     = 'whole_mean'; 
Whole_mean.name    = 'Whole mean';
Whole_mean.val     = { true };
Whole_mean.help    = {'The mean of the total value of the time series is used as the normalized baseline'};

%--------------------------------------------------------------------------
% Specify
%--------------------------------------------------------------------------
specify         = cfg_entry;
specify.tag     = 'specify'; 
specify.name    = 'Specify';
% specify.val     = {};
specify.help    = {'The range of subscript values for the time series'};
specify.num     = [1 inf];
%--------------------------------------------------------------------------
% none None
%--------------------------------------------------------------------------
none         = cfg_const;
none.tag     = 'none';
none.name    = 'None';
none.val     = { true };
none.help    = {'No normalization.'};
%--------------------------------------------------------------------------
% baseline
%--------------------------------------------------------------------------

base         = cfg_choice;
base.tag     = 'base';
base.name    = 'Baseline';
base.help    = {'Baseline for normalization of voxel time series'};
% base.labels  = {'Whole mean', 'None'};
base.values  = {Whole_mean specify none};
base.val     = {Whole_mean };


% ---------------------------------------------------------------------
% xHRF Tools
% ---------------------------------------------------------------------
cfg         = cfg_exbranch;
cfg.tag     = 'xhrf';
cfg.name    = 'xHRF';
cfg.help    = {
                  'The weighted of the hrf reaction for a certain period of time after the stimulation of the voxel is taken as the evaluation parameter beta'
}';
cfg.val  = {odir mask RT mparam generic base};
cfg.prog = @xHRF1;