% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright � 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function excitation_table = DLLGetExcitationTable( amp_index )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

	valArray = libpointer('singlePtr', single(zeros(6,3)));
    
    %  Get the excitation table from the DLL
	calllib(DLLInterface.lib, 'fmGetExcitationTable', valArray);
    excitation_table = valArray.Value;
   
end


