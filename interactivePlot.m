classdef interactivePlot < handle
    % 功能：交互式在一个figure中创建一条或者更多插值样条平面曲线，可以
    % 在曲线上任意位置双击增加插值点，在插值点右键可以删除该点，拖曳点可以实时显示插值曲线。
    %
    % 输入：
    %     points： 曲线插值点集，2*n大小，double，n>=2,形如[x1,x2,...,xn; y1,y2,...,yn]的n个平面点
    % 输出：
    %     输出曲线object及figure图像
    % Example:
    %     fig = figure();
    %     line1 = interactivePlot([7,8;5,6]);
    %     line2 = interactivePlot([2,3,4;2,3,4]);
    %     line3 = interactivePlot([2,3,4;1,1,1]);
    %
    % date: 2021.12.19
    % author:cuixingxing
    % email:cuixingxing150@gmail.com
    % matlab 2019b or later
    %
    % Reference:
    %     [1] https://au.mathworks.com/help/matlab/matlab_oop/class-methods-for-graphics-callbacks.html
    %     [2] https://au.mathworks.com/help/matlab/matlab_oop/listener-callback-functions.html
    %     [3] https://au.mathworks.com/help/matlab/matlab_oop/comparing-handle-and-value-classes.html
    properties
        hSource (1,:) images.roi.Point % 曲线上点集合对象数组
        h (1,1) matlab.graphics.chart.primitive.Line % 经过点集合的曲线
    end
    
    methods
        function obj = interactivePlot(points)
            arguments
                points (2,:) double = [0 1 1 0 -1 -1 0 0;
                    0 0 1 2 1 0 -1 -2];
            end
            curve = cscvn(points);
            pts = fnplt(curve);
            
            ax = gca;% axes(fig,'XGrid','on','YGrid','on');
            hold on;
            for i = 1:size(points,2)
                obj.hSource(i)=drawpoint(ax,'Color','r','Position',[points(1,i),points(2,i)]);
            end
            
            obj.h = plot(ax,pts(1,:),pts(2,:),'linewidth',2);
            
            addlistener(obj.hSource,'MovingROI',@(src,evt)obj.allevents(src,evt));
            obj.h.ButtonDownFcn = @(src,evt)obj.selectPoint(src,evt);
        end
        
        function allevents(obj,~,evt)
            obj.hSource(isvalid(obj.hSource)==0)=[];
            evname = evt.EventName;
            switch(evname)
                case{'MovingROI'}
                    currPt = evt.CurrentPosition;
                    for j = 1:length(obj.hSource)
                        cPt = obj.hSource(j).Position;
                        idx = all(cPt(:)==currPt(:));
                        if idx
                            break
                        end
                    end
                    obj.hSource(j).Position = currPt;
                    points1 = reshape([obj.hSource.Position],2,[]);
                    curve1 = cscvn(points1);
                    pts1 = fnplt(curve1);
                    obj.h.XData = pts1(1,:);
                    obj.h.YData = pts1(2,:);
                case{'ROIMoved'}
                    disp(['ROI moved previous position: ' mat2str(evt.PreviousPosition)]);
                    disp(['ROI moved current position: ' mat2str(evt.CurrentPosition)]);
            end
        end
        
        function selectPoint(obj,src,evt)
            % 曲线上选点并加入到点集hSource中
            type = get(src.Parent.Parent,'SelectionType');
            if strcmp(type,'open') %双击
                pt = evt.IntersectionPoint;% (x,y,z)
                ht = drawpoint('Position',[pt(1,1),pt(1,2)],'Color','r');
                ptt = [pt(1);pt(2)];
                allPoints = [src.XData;src.YData];
                [~,idx] = min(sum((ptt-allPoints).^2));
                idxs = arrayfun(@(x)obj.getIndex(x,allPoints),obj.hSource);
                insertIdx =find(idxs>=idx,1);
                obj.hSource = [obj.hSource(1:insertIdx-1),ht,obj.hSource(insertIdx:end)];
                addlistener(obj.hSource,'MovingROI',@(src,evt)obj.allevents(src,evt));
            end
        end
    end
    methods(Access = private)
        function idx = getIndex(~,x,allPoints)
            point = x.Position;
            point = [point(1);point(2)];
            [~,idx] = min(sum((point-allPoints).^2));
        end
    end
end

