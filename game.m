function game()
  % A tiny platformer: reach the green goal, avoid the red spikes.
  % Controls: left/right arrows to move, up arrow or space to jump.

  % ---- Level ----------------------------------------------------
  % Platforms: [x y width height]
  platforms = [ 0 0 40 1;      % ground
                7 2  3 0.5;
               14 3  3 0.5;
               25 2  3 0.5];
  % Spikes: [x y width]  (y = base of the spikes)
  spikes = [11 1 2;
            19 1 3;
            30 1 2];
  goal  = [37 1 1 3];          % [x y width height]
  start = [1 2];               % ball start position

  % ---- Physics --------------------------------------------------
  r      = 0.4;    % ball radius
  g      = -30;    % gravity
  speed  = 6;      % horizontal speed
  jumpV  = 12;     % jump strength
  dt     = 1/60;   % time step

  pos = start;
  vel = [0 0];
  onGround = false;

  % ---- Drawing --------------------------------------------------
  fig = figure('Name', 'Ball Game', 'NumberTitle', 'off', ...
               'KeyPressFcn', @onDown, 'KeyReleaseFcn', @onUp);
  ax = axes('Parent', fig);
  hold(ax, 'on');
  axis(ax, 'equal');
  axis(ax, [0 40 0 12]);

  for i = 1:rows(platforms)
    rectangle('Position', platforms(i,:), 'FaceColor', [0.4 0.4 0.4]);
  end
  for i = 1:rows(spikes)
    s = spikes(i,:);
    for k = 0:s(3)-1
      patch([s(1)+k, s(1)+k+0.5, s(1)+k+1], [s(2), s(2)+1, s(2)], 'r');
    end
  end
  rectangle('Position', goal, 'FaceColor', 'g');
  ball = rectangle('Position', [pos-r 2*r 2*r], 'Curvature', [1 1], ...
                   'FaceColor', 'b');

  % ---- Game loop ------------------------------------------------
  while ishandle(fig)
    % Input
    vel(1) = 0;
    if pressed(fig, 'rightarrow'), vel(1) = vel(1) + speed; end
    if pressed(fig, 'leftarrow'),  vel(1) = vel(1) - speed; end
    if onGround && (pressed(fig, 'uparrow') || pressed(fig, 'space'))
      vel(2) = jumpV;
    end

    % Move
    vel(2) = vel(2) + g*dt;
    pos = pos + vel*dt;
    pos(1) = max(pos(1), r);   % left wall

    % Land on platforms (from above only)
    onGround = false;
    for i = 1:rows(platforms)
      p = platforms(i,:);
      top = p(2) + p(4);
      if pos(1) > p(1) && pos(1) < p(1)+p(3) && vel(2) <= 0 ...
         && pos(2)-r < top && pos(2)-r > top-0.5
        pos(2) = top + r;
        vel(2) = 0;
        onGround = true;
      end
    end

    % Spikes or falling off -> restart
    hit = pos(2) < -2;
    for i = 1:rows(spikes)
      s = spikes(i,:);
      if pos(1)+r > s(1)+0.1 && pos(1)-r < s(1)+s(3)-0.1 && pos(2)-r < s(2)+0.8
        hit = true;
      end
    end
    if hit
      pos = start;
      vel = [0 0];
    end

    % Goal
    if pos(1)+r > goal(1)
      title(ax, 'You win!');
      set(ball, 'Position', [pos-r 2*r 2*r]);
      break;
    end

    set(ball, 'Position', [pos-r 2*r 2*r]);
    drawnow;
    pause(dt);
  end
end

% ---- Keyboard helpers --------------------------------------------
function onDown(src, evt)
  setappdata(src, evt.Key, true);
end

function onUp(src, evt)
  setappdata(src, evt.Key, false);
end

function k = pressed(fig, name)
  k = isappdata(fig, name) && getappdata(fig, name);
end
