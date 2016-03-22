classdef Kin2_Collector < Kin2
    % Kin2_Collector  Subclass of Kin2 that adds data capture functionality
    %   Use this class to collect data from your Kinect with the aid of
    %   timer schedulers that manage calls into Kin2.updateData() and
    %   Kin2.get<data>() methods.
    %
    % Example:
    %   k2 = Kin2_Collector('body');
    %   k2.startStreaming()
    %   % k2.<data> and k2.<data>_log propeties update without blocking
    %   k2.stopStreaming()
    %   k2.delete
    %   clear k2
    
    properties (SetAccess=private)
        
        time = [];
        depth = [];
        color = [];
        
        count = 0;
        
        streamingTimer = [];
        
    end
    
    properties (Dependent)
        
        % timeNow  Time since class instantiation in seconds
        %   Based on the built-in command 'now'
        timeNow;

        % timeNowStreaming  Time since startStreaming() in seconds
        %   Based on the built-in command 'now'
        timeNowStreaming;
        
        rateAverage;
                        
    end
    
    properties (SetAccess=private,Hidden=true)
        
        % timeInit  Time when object is instantiated in seconds
        %   Based on the built-in command 'now'
        %   This is used to compute the dependent property timeNow
        timeInit;
        
        % timeInitStreaming  Time when startStreaming() was called in
        % seconds
        timeInitStreaming;
        
        time_log;
        depth_log;
                
    end
    
    methods
        
        function this = Kin2_Collector(varargin)
            this = this@Kin2(varargin);
            this.timeInit = now*24*60*60;
        end
        
        function val = get.timeNow(this)
            val = now*24*60*60-this.timeInit;            
        end
        
        function val = get.timeNowStreaming(this)
            val = this.timeNow - this.timeInitStreaming;
        end
        
        function val = get.rateAverage(this)
            if isempty(this.streamingTimer), val = []; return; end
            val = this.count/(this.timeNow - this.timeInitStreaming);
        end
        
        function set.time(this,val)
            if isempty(this.time_log)
                this.time_log = val;
            else
                this.time_log = [this.time_log;val];
            end
            this.time = val;
        end
        
        function set.depth(this,val)
            if isempty(this.depth_log)
                this.depth_log = val;
            else
                this.depth_log(:,:,end+1) = val;
            end
            this.depth = val;
        end
        
        function startStreaming(this)
            
            if ~isempty(this.streamingTimer)
                error('Cannot start streaming when already streaming.');
            end
            
            this.streamingTimer = timer(...
                'busymode','queue',...
                'timerfcn',@this.streamingCallback,...
                'executionmode','fixedrate',...
                'name','Kin2_Collector_Streaming_Timer',...
                'period',0.01,...
                'startdelay',1);
            
            % init state to log info on streaming data
            this.count = 0;
            
            start(this.streamingTimer);
            
        end
        
        
        function streamingCallback(this,~,~)
            
            % bail if no new data
            if ~this.updateData(), return; end
            
            this.count = this.count + 1;
            this.time = this.timeNow;
            
            if isempty(this.timeInitStreaming)
                this.timeInitStreaming = this.time;
            end
                                    
            if any(strcmp('depth',this.frameSources))
                this.depth = this.getDepth();
            end
            if any(strcmp('color',this.frameSources))
                this.color = this.getColor();
            end
            
            
            
            fprintf('count = % 5d\t',this.count);
            fprintf('rate  = % 5.2f[Hz]\n',this.rateAverage);
                        
        end
        
        function stopStreaming(this)
            
            if isempty(this.streamingTimer)
                error('Cannot stop streaming when not streaming.');
            end
            
            stop(this.streamingTimer);
            delete(this.streamingTimer);
            this.streamingTimer = [];
            
            this.timeInitStreaming = [];
            
        end
                
    end
    
    
end