function OuO()
%% Create the window
clc;
%Default Constants
default_updatetime = 0.002;
%Create the update timer, used for continuously updating the game screen
update_t = timer('ExecutionMode','fixedSpacing','Period',default_updatetime,'TimerFcn',@update_face);
blink_t = timer('ExecutionMode','singleShot','StartDelay',2,'TimerFcn',@set_blink);
mood_t = timer('ExecutionMode','fixedSpacing','Period',5,'TimerFcn',@set_mood);

%Create the window
scrsz = get(0,'ScreenSize');
start_dim = min(scrsz(3)/1.5,scrsz(4)/1.5);%Used for rescaling
win = figure('DeleteFcn',@delete_timers,'ToolBar',...
    'none','Name','OuO','NumberTitle','off','MenuBar','none',...
    'Resize','off','Visible','off','Color',[0 0 0]/255,...
    'Position',[[scrsz(3),scrsz(4)]/4.5 start_dim start_dim],...
    'WindowButtonMotionFcn',@blank_function);

%% Create the UI componenets
face_axes = axes('Parent',win,'Position',[0 0 1 1]);

set(win,'Visible','on')
%% Define face features
face_size = [4;4];
lefteye_startpos = [1.1;2.5];
lefteye_currentpos = lefteye_startpos;
lefteye_setpos = lefteye_startpos;
lefteye_size = 0.3;
leftbrow_currentangles = [90 90];
leftbrow_setangles = [90 90];
leftbottom_currentangles = [90 90];
leftbottom_setangles = [90 90];

righteye_startpos = [2.9;2.5];
righteye_currentpos = righteye_startpos;
righteye_setpos = righteye_startpos;
righteye_size = 0.3;
rightbrow_currentangles = [90 90];
rightbrow_setangles = [90 90];
rightbottom_currentangles = [90 90];
rightbottom_setangles = [90 90];

blinking = 0;

mouth_centre = [2;1.5];
mouth_width = 0.5;
mouth_shift = -1;
mouth_setshift = -1;
current_mood = 'Happy';

set(face_axes,'Xlim',[0 face_size(1)],'Ylim',[0 face_size(2)],'Visible','off');
start(update_t)
start(mood_t)
%% Callback functions
    function update_face(~,~)
        cla(face_axes)
        [Xx,Yy] = get_mouse_pos();
        detect_range = 1.5;
        mouse_relative_pos = ([Xx;Yy] - face_size/2).*[1;1j];
        if (abs(mouse_relative_pos)<detect_range)
            mouse_ang = atan2d(Yy-lefteye_startpos(2),Xx-lefteye_startpos(1));
            lefteye_setpos = pos_offset(lefteye_startpos,mouse_ang,lefteye_size);
            mouse_ang = atan2d(Yy-righteye_startpos(2),Xx-righteye_startpos(1));
            righteye_setpos = pos_offset(righteye_startpos,mouse_ang,righteye_size);
            max_h = max(righteye_setpos(2),lefteye_setpos(2));
            lefteye_setpos(2) = max_h;
            righteye_setpos(2) = max_h;
        else
            lefteye_setpos = lefteye_startpos;
            righteye_setpos = righteye_startpos;
        end
        
        lefteye_currentpos = approach(lefteye_currentpos,lefteye_setpos,0.2);
        righteye_currentpos = approach(righteye_currentpos,righteye_setpos,0.2);
        if(~blinking)
            leftbrow_currentangles = approach(leftbrow_currentangles,leftbrow_setangles,0.2);
            leftbottom_currentangles = approach(leftbottom_currentangles,leftbottom_setangles,0.2);
            rightbrow_currentangles = approach(rightbrow_currentangles,rightbrow_setangles,0.2);
            rightbottom_currentangles = approach(rightbottom_currentangles,rightbottom_setangles,0.2);
            lefteye_vert = calc_eye_vertex(lefteye_currentpos,lefteye_size,leftbrow_currentangles,leftbottom_currentangles);
            righteye_vert = calc_eye_vertex(righteye_currentpos,righteye_size,rightbrow_currentangles,rightbottom_currentangles);
        else
            leftbrow_currentangles = approach(leftbrow_currentangles,[0 0],0.8);
            leftbottom_currentangles = approach(leftbottom_currentangles,[0 0],0.8);
            rightbrow_currentangles = approach(rightbrow_currentangles,[0 0],0.8);
            rightbottom_currentangles = approach(rightbottom_currentangles,[0 0],0.8);
            lefteye_vert = calc_eye_vertex(lefteye_currentpos,lefteye_size,leftbrow_currentangles,leftbottom_currentangles);
            righteye_vert = calc_eye_vertex(righteye_currentpos,righteye_size,rightbrow_currentangles,rightbottom_currentangles);
        end
        
        mouth_shift = approach(mouth_shift,mouth_setshift,0.2);
        mouth_vert = calc_mouth_vertex(mouth_centre,mouth_width,mouth_shift);
        
        draw_vertices(lefteye_vert);
        draw_vertices(righteye_vert);
        draw_vertices(mouth_vert);
        
        if(strcmp(get(blink_t,'Running'),'off'))
            start(blink_t)
        end
    end

    function delete_timers(~,~)
        %         alltimer = timerfindall('Parent',win);
        %         stop(alltimer);
        %         delete(alltimer);
        stop(update_t);
        delete(update_t);
        stop(blink_t);
        delete(blink_t);
        stop(mood_t);
        delete(mood_t);
    end
    function blank_function(~,~)
    end
    function set_blink(~,~)
        if ~blinking
            blinking = 1;
            stop(blink_t);
            set(blink_t,'StartDelay',0.1)
        else
            blinking  = 0;
            stop(blink_t);
            set(blink_t,'StartDelay',round((rand(1)*1.9+0.1)*1000)/1000)
        end
    end
    function set_mood(~,~)
        moods = {'Happy','Neutral','Sad'};
        selected_mood = round(rand(1)*(length(moods)-1)+1);
        current_mood = moods{selected_mood};
        determine_mood_face();
    end
%% Non Callback Functions
    function[eye_vertices] = calc_eye_vertex(centre,radius,brow_angles,bottom_angles)
        eye_top_vertices = cutoff_circle_vertice(centre,radius,brow_angles);
        eye_bottom_vertices = cutoff_circle_vertice(centre,radius,bottom_angles);
        eye_bottom_vertices = fliplr(eye_bottom_vertices);
        eye_bottom_vertices(2,:) = eye_bottom_vertices(2,:)- 2*(eye_bottom_vertices(2,:)-centre(2));
        
        eye_vertices = [eye_top_vertices eye_bottom_vertices];
    end
    function[mouth_vertices] = calc_mouth_vertex(centre,width,cen_y_offset)
        P0 = centre - [width;0];P2 = centre + [width;0];
        P1 = centre+[0;cen_y_offset];
        mouth_vertices = quad_beizer(P0,P1,P2);
        bot = quad_beizer(P0,P1-[0;0.1],P2);
        bot = fliplr(bot);
        mouth_vertices = [mouth_vertices bot];
    end
    function draw_vertices(vertices)
        patch(vertices(1,:),vertices(2,:),[1 1 1],'Parent',face_axes)
    end
    function [offset_pos] = pos_offset(ori_pos,angle,radius_limit)
        offset_pos = ori_pos+radius_limit*[cosd(angle);sind(angle)];
    end
    function[val] =  approach(start_val,end_val,incre)
        val = start_val + (end_val - start_val)*incre;
    end

    function[X,Y]= get_mouse_pos()
        mpos = get(face_axes,'CurrentPoint');
        X = mpos(1,1);
        Y = mpos(1,2);
    end
    function[vertices] = cutoff_circle_vertice(centre,radius,end_angles)
        n_of_vertices = 7+1; %because need to reach 90 degrees
        left_increment = end_angles(1)/(n_of_vertices-1);
        right_increment = end_angles(2)/(n_of_vertices-1);
        vertices = zeros(2,n_of_vertices*2);
        for i = 1:n_of_vertices
            theta = 180 - left_increment*(i-1);
            vertices(1,i) = centre(1)+radius*cosd(theta);
            vertices(2,i) = centre(2)+radius*sind(theta);
            theta = 0 + right_increment*(i-1);
            vertices(1,end+1-i) = centre(1)+radius*cosd(theta);
            vertices(2,end+1-i) = centre(2)+radius*sind(theta);
        end
    end
    function[vertices] = quad_beizer(P0,P1,P2)
        t = 0:0.05:1;
        vertices = zeros(2,length(t));
        for n = 1:length(t)
            vertices(:,n) = power(1-t(n),2).*P0 + 2*(1-t(n))*t(n).*P1 + power(t(n),2).*P2;
        end
    end
    function determine_mood_face()
        switch(current_mood)
            case 'Happy'
                leftbrow_setangles = [90 90];
                leftbottom_setangles = [90 90];
                rightbrow_setangles = [90 90];
                rightbottom_setangles = [90 90];
                mouth_setshift = -0.5;
            case 'Neutral'
                leftbrow_setangles = [90 90];
                leftbottom_setangles = [90 90];
                rightbrow_setangles = [90 90];
                rightbottom_setangles = [90 90];
                mouth_setshift = 0;
            case 'Sad'
                leftbrow_setangles = [30 60];
                leftbottom_setangles = [90 90];
                rightbrow_setangles = [60 30];
                rightbottom_setangles = [90 90];
                mouth_setshift = 1;
        end
    end
end