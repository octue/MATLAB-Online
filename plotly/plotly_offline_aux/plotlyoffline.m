function response = plotlyoffline(plotlyfig)
    % Generate offline Plotly figure saved as an html file within 
    % the current working directory. The file will be saved as: 
    % 'plotlyfig.PlotOptions.FileName'.html. 
    
    % create dependency string unless not required
    if plotlyfig.PlotOptions.IncludePlotlyjs
        % grab the bundled dependencies
        userhome = getuserdir();
        plotly_config_folder   = fullfile(userhome,'.plotly');
        plotly_js_folder = fullfile(plotly_config_folder, 'plotlyjs');
        bundle_name = 'plotly-matlab-offline-bundle.js';
        bundle_file = fullfile(plotly_js_folder, bundle_name);

        % Check that the bundle exists, attempt to download if not
        if ~exist(bundle_file, 'file')
            %TODO move bundle_url to plotly config
            bundle_url = 'http://cdn.plot.ly/plotly-latest.min.js';
            warning('No plotly offline file: %s.\nAttempting to download required dependency from %s',...
                    bundle_file,...
                    bundle_url)
            bundle_dir = fileparts(bundle_file);
            mkdir(bundle_dir);
            websave(bundle_file, bundle_url);
        end
        
        % template dependencies
        dep_script = sprintf('<script src="%s"></script>\n', bundle_file);
        
    else
        dep_script = '';
    end
    
    % handle plot div specs
    id = char(java.util.UUID.randomUUID); 
    width = [num2str(plotlyfig.layout.width) 'px']; 
    height = [num2str(plotlyfig.layout.height) 'px']; 
    
    if plotlyfig.PlotOptions.ShowLinkText
        link_text = plotlyfig.PlotOptions.LinkText;   
    else
        link_text = ''; 
    end
    
    % format the data and layout
    jdata = m2json(plotlyfig.data); 
    jlayout = m2json(plotlyfig.layout);
    clean_jdata = escapechars(jdata); 
    clean_jlayout = escapechars(jlayout);
    
    % template environment vars
    plotly_domain = plotlyfig.UserData.PlotlyDomain;
    env_script = sprintf(['<script type="text/javascript">', ...
                          'window.PLOTLYENV=window.PLOTLYENV || {};', ...
                          'window.PLOTLYENV.BASE_URL="%s";', ...
                          'Plotly.LINKTEXT="%s";', ...
                          '</script>'], plotly_domain, link_text); 
        
    % template Plotly.plot   
    script = sprintf(['\n Plotly.plot("%s", %s, %s).then(function(){'...
                      '\n    $(".%s.loading").remove();' ...
                      '\n    $(".link--embedview").text("%s");'...
                      '\n    });'], id, clean_jdata, clean_jlayout, ...
                      id, link_text);
    
    plotly_script = sprintf(['\n<div class="%s loading" style=', ...
                             'color: rgb(50,50,50);"></div>' ... << TODO insert 'Drawing...' as text in this div if jquery available
                             '\n<div id="%s" style="height: %s;',...
                             'width: %s;" class="plotly-graph-div">' ...
                             '</div> \n<script type="text/javascript">' ...
                             '%s \n</script>'], id, id, height, width, ... 
                             script);
    
    % The plot function requires jquery (slim, min, only) as a dependency 
    % to use the $() operator. If it's not there, then the 'Drawing' text
    % and embeddable link don't get updated on plot... temporarily removed
    offline_script = sprintf('<head>\n%s\n%s\n</head>\n<body>\n%s\n%s\n</body>', dep_script, env_script, plotly_script);

    filename = plotlyfig.PlotOptions.FileName; 
    
    % remove the whitespace from the filename
    clean_filename = filename(filename~=' '); 
    html_filename = [clean_filename '.html'];
    
    % save the html file in the working directory
    plotly_offline_file = fullfile(pwd, html_filename); 
    file_id = fopen(plotly_offline_file, 'w');
    fprintf(file_id, offline_script); 
    fclose(file_id); 
    
    % remove any whitespace from the plotly_offline_file path
    plotly_offline_file = strrep(plotly_offline_file, ' ', '%20'); 
    
    % return the local file url to be rendered in the browser
    response = ['file://' plotly_offline_file]; 
    
end
