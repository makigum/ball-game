function cortical_maze_neuroscience_game() % Launches the complete cortical-migration educational maze game as the main MATLAB/Octave function.
% CORTICAL MAZE: INSIDE-OUT is a neuroscience game built around corticogenesis and neuronal migration. % States the game's educational foundation so the code can be presented and explained clearly.
% The central concept is the inside-out lamination sequence: Layer VI, then V, then IV, then II/III, with Layer I/MZ as the final superficial stop. % Connects the game progression directly to the supplied corticogenesis material.
% The maze also models radial versus tangential migration, radial-glial guidance, Reelin-dependent stopping, and adaptive shortcuts that mimic learning. % Explains the main mechanics before any executable logic begins.
% The game is intentionally procedural, so every visual is generated with basic MATLAB/Octave graphics primitives and no external assets are needed. % Documents the graphics constraint required by the assignment.

close all; % Closes previously open figure windows so the game starts from a clean graphical state.
clc; % Clears the command window so optional messages from the game are easier to read.
rng('shuffle'); % Seeds the random number generator so each run produces a fresh maze layout and cue placement.

fig = figure('Name','Cortical Maze: Inside-Out','NumberTitle','off','Color',[0.96 0.97 1.00],'MenuBar','none','ToolBar','none','KeyPressFcn',@key_handler); % Creates the single game window, applies a soft background, hides cluttering toolbars, and connects keyboard input to the game callback.
set(fig,'Position',[80 60 1180 780]); % Places the game window at a comfortable desktop size so the maze, HUD, and instructions remain visible together.
ax = axes('Parent',fig); % Creates the main axes object that will hold the procedural cartoon graphics and the game interface.
set(ax,'Color',[0.985 0.985 1.000]); % Gives the play area a very pale background that keeps the pastel layer bands readable.
axis(ax,[0 31 0 24]); % Sets a fixed coordinate system with enough room for a 26-by-18 maze plus a compact upper HUD area.
axis(ax,'equal'); % Keeps maze cells square so spatial navigation is visually faithful to the underlying grid.
axis(ax,'off'); % Hides ordinary axis ticks and borders because the game supplies its own labels and styling.
hold(ax,'on'); % Allows background layers, maze walls, cues, player, and text to coexist in one axes without overwriting each other.

state.phase = 'menu'; % Starts the program on the menu screen instead of immediately moving the player.
state.mode = 1; % Selects the default neuron type, with mode 1 representing a pyramidal/glutamatergic neuron.
state.running = false; % Keeps the movement loop inactive until the player deliberately starts the game.
state.quit = false; % Stores whether the user has requested that the program terminate.
state.quitArmUntil = 0; % Tracks the deadline for a confirming second Q press so one accidental tap cannot instantly end a run.
state.paused = false; % Stores whether gameplay is temporarily paused by the spacebar.
state.gameOver = false; % Records whether the active run has reached a win or lose condition.
state.score = 0; % Initializes the cumulative score used to reward efficient movement and correct molecular choices.
state.lives = 3; % Gives the player three mistakes before the run ends, making experimentation safe but meaningful.
state.stage = 1; % Starts the developmental sequence at the first migration milestone.
state.moves = 0; % Counts all successful cell-to-cell moves and provides a simple efficiency measure.
state.stageMoves = 0; % Counts successful moves during only the current developmental stage for adaptive difficulty.
state.wallBumps = 0; % Counts blocked attempts so the game can gently penalize repeated collisions without immediately ending the run.
state.wrongCues = 0; % Counts incorrect molecular marker choices because they represent conceptual mistakes.
state.assistLevel = 0; % Controls how many extra shortcut passages are added when the player struggles, modelling adaptive support.
state.bestStreak = 0; % Tracks the largest sequence of correct cues reached during the current session.
state.streak = 0; % Tracks the current correct-cue streak for reward feedback.
state.showGuide = false; % Keeps the optional field guide hidden during normal play so the player can retrieve information from memory.
state.guideUntil = 0; % Stores the time at which the temporary field guide should disappear.
state.message = ''; % Holds a short contextual feedback sentence shown beneath the main title.
state.messageUntil = 0; % Stores the expiration time for the temporary feedback message.
state.lastStep = tic; % Creates a timer used to throttle grid movement to a comfortable arcade-like speed.
state.gameClock = tic; % Creates the main timer used for total run duration and end-screen reporting.
state.stageClock = tic; % Creates a stage timer used to compute speed bonuses and guide adaptive difficulty.
state.phaseDirty = true; % Requests an initial menu render because nothing has yet been drawn.
state.mazeDirty = true; % Requests an initial maze render once play begins.
state.direction = [0 1]; % Gives the player an initial upward direction that fits radial migration.
state.facing = [0 1]; % Remembers the last real heading so the neuron's dendrites/axon still point somewhere after a wall stops state.direction at [0 0].
state.player = [5 1]; % Places the default pyramidal neuron inside the ventricular-zone area near the bottom of the cortex.
state.trail = []; % Starts with an empty short-lived migration trace that will grow as the neuron moves.
state.rows = 18; % Defines the number of maze rows and simultaneously provides enough vertical room for the major cortical compartments.
state.cols = 26; % Defines the number of maze columns and creates a wide enough field for branching navigation.
state.vWalls = []; % Reserves the matrix that stores vertical maze walls between horizontally adjacent cells.
state.hWalls = []; % Reserves the matrix that stores horizontal maze walls between vertically adjacent cells.
state.cuePos = []; % Reserves the coordinates of the three molecular-cue choices shown in each stage.
state.cueLabels = {}; % Reserves the text labels attached to the molecular-cue choices.
state.correctCue = 1; % Initializes the correct cue index before a stage is prepared.
state.targetInfo = struct(); % Creates an empty structure that will later hold the current developmental target information.
state.shortcutCount = 0; % Stores the number of adaptive maze shortcuts currently available.
state.playerHandle = []; % Reserves the graphics handle for the cartoon neuron body.
state.nucleusHandle = []; % Reserves the graphics handle for the cartoon neuron nucleus.
state.dendriteHandles = []; % Reserves the graphics handles for the branching dendrite lines so the player reads as a neuron rather than a plain ball.
state.axonHandle = []; % Reserves the graphics handle for the single trailing axon line.
state.axonBulbHandle = []; % Reserves the graphics handle for the small axon-terminal bouton at the tip of the axon.
state.trailHandle = []; % Reserves the graphics handle for the fading migration trace.
state.cueHandles = []; % Reserves the graphics handles for the three molecular cue icons.
state.cueTextHandles = []; % Reserves the text handles for the three molecular cue labels.
state.hudHandles = []; % Reserves the text handles used by the upper HUD and status messages.
state.helpHandles = []; % Reserves temporary text handles used by the working-memory field guide.

render_menu(); % Draws the initial start screen immediately so the player sees the concept, controls, and mode choices.

while ~state.quit && ishandle(fig) % Keeps the game responsive until the player quits or closes the figure window.
    drawnow(); % Flushes graphics and callback events so keyboard input is handled smoothly rather than waiting for the loop to finish.
    if strcmp(state.phase,'menu') % Checks whether the game is still on the start screen.
        if state.phaseDirty % Re-renders the menu only when something changed, avoiding unnecessary full-screen redraws.
            render_menu(); % Updates the start screen after a mode change or return from another screen.
        end % Ends the menu-dirty check.
        pause(0.02); % Waits a tiny amount so the CPU is not consumed by a busy loop while still keeping input responsive.
    elseif strcmp(state.phase,'playing') % Checks whether an active run is currently underway.
        if ~state.paused % Executes the movement and adaptive game loop only when the player has not paused the game.
            if toc(state.lastStep) >= move_interval() % Tests whether enough real time has passed for the next grid movement.
                state.lastStep = tic; % Resets the movement timer immediately so each move has a predictable cadence.
                step_game(); % Processes one movement attempt, collisions, cues, score changes, and possible stage transitions.
            end % Ends the movement-timing check.
        end % Ends the not-paused branch.
        update_dynamic_graphics(); % Refreshes the player, trail, HUD timer, and temporary feedback without rebuilding the maze every frame.
        pause(0.01); % Keeps the animation smooth while still allowing the callback system to process keys rapidly.
    elseif strcmp(state.phase,'end') % Checks whether the player has won or lost and is waiting at the final results screen.
        if state.phaseDirty % Re-renders the results screen only after reaching it or restarting from it.
            render_end_screen(); % Draws the final score, outcome, and available next actions.
        end % Ends the end-screen dirty check.
        pause(0.02); % Keeps the end screen responsive to restart, menu, and quit keys.
    else % Handles the impossible case defensively so a corrupted phase cannot trap the loop forever.
        state.quit = true; % Exits safely if the state machine somehow contains an unknown phase value.
    end % Ends the top-level game-state selection.
end % Ends the main interactive game loop.

if ishandle(fig) % Checks whether the user closed the game window manually before the loop ended.
    delete(fig); % Cleans up the figure object so the MATLAB/Octave session is left tidy.
end % Ends the figure cleanup check.

    function dt = move_interval() % Returns the time in seconds between automatic cell movements and makes the arcade pace easy to modify.
        dt = 0.12; % Chooses roughly eight grid moves per second, which is fast enough to feel responsive but slow enough for deliberate maze decisions.
    end % Ends the move-interval helper function.

    function key_handler(~,event) % Receives every key press from the figure and translates it into menu, movement, pause, help, or restart actions.
        key = lower(event.Key); % Normalizes the pressed key to lowercase so the controls behave identically with or without shift/caps lock.
        if strcmp(state.phase,'menu') % Checks whether keyboard input should be interpreted as a menu choice.
            if strcmp(key,'1') % Tests whether the player selected the pyramidal-neuron mode.
                state.mode = 1; % Stores pyramidal/glutamatergic migration as the selected game mode.
                state.message = 'Mode selected: pyramidal neuron - radial migration.'; % Gives immediate feedback linking the mode to the neuroscience concept.
                state.messageUntil = inf; % Keeps the selection message visible until the player starts or changes it.
                state.phaseDirty = true; % Requests a menu refresh so the highlighted choice changes on screen.
            elseif strcmp(key,'2') % Tests whether the player selected the interneuron mode.
                state.mode = 2; % Stores interneuron/GABAergic migration as the selected game mode.
                state.message = 'Mode selected: interneuron - tangential first, then radial.'; % Links the mode to the documented two-step migration strategy.
                state.messageUntil = inf; % Keeps the selection message visible until the next menu action.
                state.phaseDirty = true; % Requests a menu refresh so the highlighted choice changes on screen.
            elseif strcmp(key,'leftarrow') || strcmp(key,'left') % Lets the left arrow highlight the pyramidal card, matching its position on the left side of the menu.
                state.mode = 1; % Stores pyramidal/glutamatergic migration as the selected game mode.
                state.message = 'Mode selected: pyramidal neuron - radial migration.'; % Gives immediate feedback linking the mode to the neuroscience concept.
                state.messageUntil = inf; % Keeps the selection message visible until the player starts or changes it.
                state.phaseDirty = true; % Requests a menu refresh so the highlighted choice changes on screen.
            elseif strcmp(key,'rightarrow') || strcmp(key,'right') % Lets the right arrow highlight the interneuron card, matching its position on the right side of the menu.
                state.mode = 2; % Stores interneuron/GABAergic migration as the selected game mode.
                state.message = 'Mode selected: interneuron - tangential first, then radial.'; % Links the mode to the documented two-step migration strategy.
                state.messageUntil = inf; % Keeps the selection message visible until the next menu action.
                state.phaseDirty = true; % Requests a menu refresh so the highlighted choice changes on screen.
            elseif strcmp(key,'return') || strcmp(key,'space') % Checks for the enter or space key as the universal start command.
                reset_game(); % Initializes a new run using the currently selected neuron type and starts the maze.
            elseif strcmp(key,'q') % Checks for q as the quit command (escape no longer quits; it now means "go to menu", and the menu is already shown here).
                state.quit = true; % Requests clean termination of the program.
            end % Ends the menu key-choice logic.
        elseif strcmp(state.phase,'playing') % Checks whether the same keyboard input should instead control the active neuron.
            if strcmp(key,'uparrow') || strcmp(key,'up') || strcmp(key,'w') % Maps the up arrow (both Octave/MATLAB key-name spellings) and W key to upward migration.
                state.direction = [0 1]; % Stores an upward one-cell direction so the player can move toward superficial layers.
                state.facing = state.direction; % Remembers this heading so the neuron's dendrites/axon still point the right way after a future wall stop.
            elseif strcmp(key,'downarrow') || strcmp(key,'down') || strcmp(key,'s') % Maps the down arrow (both spellings) and S key to downward migration.
                state.direction = [0 -1]; % Stores a downward one-cell direction for backtracking and route planning.
                state.facing = state.direction; % Remembers this heading so the neuron's dendrites/axon still point the right way after a future wall stop.
            elseif strcmp(key,'leftarrow') || strcmp(key,'left') || strcmp(key,'a') % Maps the left arrow (both spellings) and A key to leftward movement.
                state.direction = [-1 0]; % Stores a leftward one-cell direction for tangential travel and maze exploration.
                state.facing = state.direction; % Remembers this heading so the neuron's dendrites/axon still point the right way after a future wall stop.
            elseif strcmp(key,'rightarrow') || strcmp(key,'right') || strcmp(key,'d') % Maps the right arrow (both spellings) and D key to rightward movement.
                state.direction = [1 0]; % Stores a rightward one-cell direction for tangential travel and maze exploration.
                state.facing = state.direction; % Remembers this heading so the neuron's dendrites/axon still point the right way after a future wall stop.
            elseif strcmp(key,'space') % Checks whether the player pressed the spacebar during active play.
                state.paused = ~state.paused; % Toggles pause status so the player can stop the moving maze without losing progress.
                if state.paused % Checks whether the game has just entered the paused state.
                    state.message = 'Paused - press SPACE again to resume.'; % Gives an explicit resume instruction in the HUD.
                    state.messageUntil = inf; % Keeps the pause message visible as long as the game remains paused.
                else % Handles the transition back into normal play.
                    state.message = 'Resumed - find the correct developmental cue.'; % Reorients the player toward the core objective after unpausing.
                    state.messageUntil = toc(state.gameClock) + 2; % Shows the resume message for two seconds rather than permanently.
                end % Ends the pause-state feedback logic.
            elseif strcmp(key,'h') % Checks whether the player requested the optional molecular marker field guide.
                state.showGuide = true; % Temporarily reveals the mapping between layers and molecular markers to support memory retrieval rather than passive reading.
                state.guideUntil = toc(state.gameClock) + 3; % Keeps the guide visible for only three seconds so using it still requires active recall.
                state.score = max(0,state.score - 3); % Applies a small score cost to make the help system a deliberate strategic choice.
                state.message = 'Memory aid used: -3 points.'; % Tells the player why the score changed and frames the tool as assistance rather than punishment.
                state.messageUntil = toc(state.gameClock) + 1.5; % Shows the feedback briefly so it does not dominate the screen.
            elseif strcmp(key,'escape') % Checks for escape during active play, which now means "go back to the menu" rather than quitting the app.
                state.phase = 'menu'; % Switches the state machine back to the start screen, abandoning the current run.
                state.running = false; % Marks the active movement loop as finished for clarity, matching how a completed run is marked.
                state.phaseDirty = true; % Requests the menu screen to be redrawn.
            elseif strcmp(key,'q') % Checks for q during active play, the dedicated (and still confirmed) quit-the-whole-game command.
                if toc(state.gameClock) <= state.quitArmUntil % Checks whether this is the confirming second press within the short arming window.
                    state.quit = true; % Exits the game cleanly now that the player has confirmed the quit.
                else % Handles the first press, which only arms the quit instead of exiting immediately.
                    state.quitArmUntil = toc(state.gameClock) + 2; % Opens a brief window during which a repeat press confirms the quit.
                    state.message = 'Press Q again to quit - ESC returns to menu - any other key cancels.'; % Prevents a single accidental tap next to W/A/S/D from silently ending the run, and documents the new ESC shortcut.
                    state.messageUntil = toc(state.gameClock) + 2; % Keeps the confirmation prompt visible for the same duration as the arming window.
                end % Ends the quit-confirmation check.
            end % Ends the active gameplay key-choice logic.
        elseif strcmp(state.phase,'end') % Checks whether key input should control the results screen.
            if strcmp(key,'r') || strcmp(key,'return') || strcmp(key,'space') % Allows any of three intuitive keys to restart immediately.
                reset_game(); % Begins a fresh run using the same selected neuron mode.
            elseif strcmp(key,'m') || strcmp(key,'escape') % Allows the player to return to the neuron-selection menu; escape is now a synonym for M everywhere instead of quitting.
                state.phase = 'menu'; % Switches the state machine back to the start screen.
                state.phaseDirty = true; % Requests the menu screen to be redrawn.
            elseif strcmp(key,'q') % Accepts q as the results-screen quit control.
                state.quit = true; % Requests clean termination of the game.
            end % Ends the results-screen key-choice logic.
        end % Ends the phase-dependent keyboard handler.
    end % Ends the keyboard callback function.

    function reset_game() % Creates a fresh game state, builds the first maze, and prepares the first developmental challenge.
        state.phase = 'playing'; % Changes the state machine from menu or end screen into live gameplay.
        state.running = true; % Marks the run as active for clarity even though the phase variable controls the loop.
        state.paused = false; % Ensures a restarted game never begins in a paused state.
        state.quitArmUntil = 0; % Clears any pending quit-confirmation window left over from a previous run.
        state.gameOver = false; % Clears any previous win or loss flag so the new run can progress normally.
        state.score = 0; % Resets the player's score for a fair new attempt.
        state.lives = 3; % Restores the full set of three mistake tokens.
        state.stage = 1; % Returns to the earliest developmental milestone.
        state.moves = 0; % Resets the total movement counter used for efficiency statistics.
        state.stageMoves = 0; % Resets the current-stage movement counter.
        state.wallBumps = 0; % Clears the count of blocked movement attempts.
        state.wrongCues = 0; % Clears the count of molecular-choice errors.
        state.assistLevel = 0; % Starts the adaptive-learning system at neutral difficulty.
        state.bestStreak = 0; % Resets the session's best correct-cue streak.
        state.streak = 0; % Resets the current correct-choice streak.
        state.lastStep = tic; % Restarts the grid-movement timer for the first stage.
        state.gameClock = tic; % Restarts the total-run stopwatch used by the end screen.
        state.stageClock = tic; % Restarts the current-stage stopwatch used for speed bonuses.
        state.message = 'Migrate in the correct developmental order and collect the correct marker.'; % States the objective in one sentence so the player knows what success looks like.
        state.messageUntil = toc(state.gameClock) + 4; % Keeps the objective visible during the opening seconds of the run.
        state.showGuide = false; % Hides the field guide after a restart so the player must actively recall the mapping again.
        state.guideUntil = 0; % Clears any previously scheduled guide expiration.
        state.phaseDirty = true; % Marks the screen for rendering after the reset.
        state.mazeDirty = true; % Requests a fresh maze layout for the new run.
        if state.mode == 1 % Checks whether the player selected the pyramidal neuron mode.
            state.player = [5 1]; % Starts pyramidal neurons near the ventricular zone, matching their cortical origin.
            state.direction = [0 1]; % Points the initial migration upward so the first natural movement is radial.
            state.facing = [0 1]; % Keeps the drawn neuron facing the same initial direction as its migration.
        else % Handles the interneuron mode in which cells begin outside the cortical plate.
            state.player = [2 5]; % Starts interneurons in a left-side MGE/CGE-like source region represented by the subpallial strip.
            state.direction = [1 0]; % Points the initial movement rightward to encourage the documented tangential migration phase.
            state.facing = [1 0]; % Keeps the drawn neuron facing the same initial direction as its migration.
        end % Ends the mode-dependent starting-position logic.
        state.trail = state.player; % Seeds the migration trace with the starting position for a cute visual footprint.
        build_stage(); % Generates the first stage target, maze, and molecular cues.
    end % Ends the game-reset function.

    function build_stage() % Creates a new maze and the molecular-cue puzzle appropriate for the current developmental milestone.
        state.shortcutCount = 1 + state.assistLevel; % Opens more shortcut passages when the adaptive system detects that the player needs help.
        [state.vWalls,state.hWalls] = generate_maze(state.rows,state.cols,state.shortcutCount); % Builds a fresh connected maze whose layout changes between developmental stages.
        state.mazeDirty = true; % Marks the maze as needing a redraw because its wall structure has changed.
        state.stageMoves = 0; % Resets the stage-specific movement counter so the next transition can measure efficiency fairly.
        state.stageClock = tic; % Starts a new stopwatch for the current developmental milestone.
        state.cuePos = zeros(3,2); % Allocates space for exactly three possible molecular cues in every stage.
        state.cueLabels = cell(1,3); % Allocates three labels so the molecular marker puzzle can present one correct answer plus two distractors.
        info = get_stage_info(state.stage,state.mode); % Retrieves the neuroscience information that defines the current target and its correct marker.
        state.targetInfo = info; % Stores the stage description so the HUD and collision logic can refer to it later.
        if state.mode == 2 && state.stage == 1 % Checks for the special interneuron-only entry stage.
            baseRows = [4 5 6]; % Places the first target near the lower cortical border so the player must travel tangentially from the MGE/CGE side.
            state.correctCue = randi(3); % Randomizes which cue position contains the correct cortical-entry signal so memorizing one location is impossible.
            state.cueLabels = {'Enter cortex','Stay tangential','Reverse migration'}; % Gives the entry stage three conceptual choices so the player must recognize the correct migration strategy rather than simply selecting any identical icon.
        else % Handles the ordinary layer-and-marker stages shared by both neuron modes.
            baseRows = info.rowRange; % Uses the target layer's row range so cue choices visually correspond to the correct cortical depth.
            state.correctCue = randi(3); % Randomizes the spatial position of the correct molecular marker on every stage.
            decoys = info.decoys; % Retrieves two biologically plausible but incorrect markers that are useful as learning distractors.
            labels = {info.marker,decoys{1},decoys{2}}; % Creates the three candidate answers for the current layer.
            order = randperm(3); % Randomizes the order so the correct answer is not consistently the first icon.
            state.cueLabels = labels(order); % Reorders the displayed marker labels using the random permutation.
            state.correctCue = find(order == 1); % Finds which displayed position now contains the true marker after randomization.
        end % Ends the entry-stage versus layer-stage cue construction.
        for k = 1:3 % Places three distinct cue icons within the appropriate cortical region.
            candidate = [randi(state.cols) baseRows(randi(numel(baseRows)))]; % Chooses a random cell inside the target band for the current cue.
            while any(all(state.cuePos(1:max(1,k-1),:) == candidate,2)) || all(candidate == round(state.player)) % Rejects duplicate positions and prevents a cue from appearing directly underneath the player.
                candidate = [randi(state.cols) baseRows(randi(numel(baseRows)))]; % Draws another candidate until the position is distinct and playable.
            end % Ends the candidate-position validity loop.
            state.cuePos(k,:) = candidate; % Saves the approved cue coordinate in the stage state.
        end % Ends the three-cue placement loop.
        state.message = stage_message(); % Creates a brief stage-specific instruction that links the mechanic to the neuroscience concept.
        state.messageUntil = toc(state.gameClock) + 4; % Displays the new-stage message long enough to be noticed without interrupting play.
        render_playfield(); % Draws the new maze, layer bands, cues, and player so the player can immediately act.
    end % Ends the stage-building function.

    function [vWalls,hWalls] = generate_maze(rows,cols,shortcuts) % Generates a connected grid maze with optional shortcut openings for adaptive assistance.
        vWalls = ones(rows,cols-1); % Initializes every possible vertical separator as a wall before the maze-carving algorithm begins.
        hWalls = ones(rows-1,cols); % Initializes every possible horizontal separator as a wall before carving passages.
        visited = false(rows,cols); % Tracks which cells have already been reached by the depth-first maze generator.
        stack = zeros(rows*cols,2); % Allocates a stack large enough to hold every cell coordinate in the worst case.
        top = 1; % Places the starting cell at the top of the depth-first search stack.
        stack(top,:) = [1 1]; % Seeds the maze generator at the lower-left cell so the board is always connected from the beginning.
        visited(1,1) = true; % Marks the first cell as visited so it cannot be added to the stack twice.
        while top > 0 % Continues carving until the backtracking stack is empty, meaning every cell has been visited.
            current = stack(top,:); % Reads the most recently added cell to implement randomized depth-first search.
            cr = current(1); % Extracts the current row index from the stacked coordinate.
            cc = current(2); % Extracts the current column index from the stacked coordinate.
            candidates = []; % Starts an empty list of unvisited neighboring cells for this step.
            if cr > 1 && ~visited(cr-1,cc) % Tests whether an unvisited neighbor exists below the current cell.
                candidates(end+1,:) = [cr-1 cc 1]; % Stores the lower neighbor and encodes direction 1 for a vertical wall removal.
            end % Ends the lower-neighbor check.
            if cr < rows && ~visited(cr+1,cc) % Tests whether an unvisited neighbor exists above the current cell.
                candidates(end+1,:) = [cr+1 cc 2]; % Stores the upper neighbor and encodes direction 2 for a vertical wall removal.
            end % Ends the upper-neighbor check.
            if cc > 1 && ~visited(cr,cc-1) % Tests whether an unvisited neighbor exists to the left of the current cell.
                candidates(end+1,:) = [cr cc-1 3]; % Stores the left neighbor and encodes direction 3 for a horizontal wall removal.
            end % Ends the left-neighbor check.
            if cc < cols && ~visited(cr,cc+1) % Tests whether an unvisited neighbor exists to the right of the current cell.
                candidates(end+1,:) = [cr cc+1 4]; % Stores the right neighbor and encodes direction 4 for a horizontal wall removal.
            end % Ends the right-neighbor check.
            if isempty(candidates) % Checks whether the current cell is a dead end in the depth-first search.
                top = top - 1; % Backtracks to the previous cell so another unexplored branch can be carved.
            else % Handles the case where at least one new neighboring cell is available.
                pick = candidates(randi(size(candidates,1)),:); % Chooses one candidate at random so every stage gets a different maze structure.
                nr = pick(1); % Extracts the chosen neighbor's row index.
                nc = pick(2); % Extracts the chosen neighbor's column index.
                directionCode = pick(3); % Extracts the stored direction code needed to remove the correct wall.
                if directionCode == 1 % Checks whether the chosen neighbor is below the current cell.
                    hWalls(cr-1,cc) = 0; % Removes the horizontal wall separating the current cell and the lower neighbor.
                elseif directionCode == 2 % Checks whether the chosen neighbor is above the current cell.
                    hWalls(cr,cc) = 0; % Removes the horizontal wall separating the current cell and the upper neighbor.
                elseif directionCode == 3 % Checks whether the chosen neighbor is to the left.
                    vWalls(cr,cc-1) = 0; % Removes the vertical wall separating the current cell and the left neighbor.
                else % Handles the only remaining case, which is the right neighbor.
                    vWalls(cr,cc) = 0; % Removes the vertical wall separating the current cell and the right neighbor.
                end % Ends the wall-removal direction selection.
                visited(nr,nc) = true; % Marks the chosen neighbor as visited so the maze remains a spanning tree rather than containing disconnected cells.
                top = top + 1; % Pushes the newly visited neighbor onto the depth-first search stack.
                stack(top,:) = [nr nc]; % Stores the neighbor coordinate at the new top of the stack.
            end % Ends the maze-generation step for the current cell.
        end % Ends the full depth-first search once the stack becomes empty.
        for k = 1:shortcuts % Adds a small number of extra openings so stronger performance produces a slightly harder but still fully connected maze.
            cr = randi(rows); % Chooses a random row for an adaptive shortcut.
            cc = randi(cols); % Chooses a random column for an adaptive shortcut.
            if rand < 0.5 && cc < cols % Randomly attempts to remove a horizontal separator between left and right cells.
                vWalls(cr,cc) = 0; % Opens that separator, creating a loop and therefore a useful shortcut.
            elseif cr < rows % Handles the alternative of opening a vertical separator between lower and upper cells.
                hWalls(cr,cc) = 0; % Opens that separator, creating another shortcut through the maze.
            end % Ends the shortcut-orientation choice.
        end % Ends the adaptive shortcut loop.
    end % Ends the procedural maze generator.

    function info = get_stage_info(stage,mode) % Returns the developmental stage name, correct marker, layer location, and plausible decoy markers.
        info = struct(); % Creates an empty structure so each stage can fill the same standardized fields.
        info.rowRange = [3 5]; % Defaults the target band to Layer VI for the first ordinary stage.
        info.layer = 'Layer VI'; % Defaults the biological layer label to the first deep cortical layer.
        info.marker = 'Tbr1'; % Defaults the molecular identity marker to the Layer VI transcription factor described in the source material.
        info.decoys = {'Ctip2','Rorb'}; % Defaults two wrong markers that belong to other cortical layers and therefore make meaningful distractors.
        if mode == 2 && stage == 1 % Checks for the interneuron-specific migration entry stage.
            info.layer = 'Cortical entry'; % Labels the first target as the point where tangential migration enters the developing cortex.
            info.marker = 'Enter cortex'; % Uses a conceptual cue instead of a molecular marker during the tangential-entry stage.
            info.decoys = {'Stay in MGE/CGE','Reverse early'}; % Supplies conceptual distractors that represent incorrect migration strategies.
            info.rowRange = [4 6]; % Places the entry cue near the lower cortical border where a tangentially migrating interneuron can enter.
        elseif stage == 1 || (mode == 2 && stage == 2) % Checks for the Layer VI stage after either starting route.
            info.layer = 'Layer VI'; % Identifies the deepest definitive cortical layer in the game's inside-out sequence.
            info.marker = 'Tbr1'; % Uses Tbr1 because the supplied material identifies it as a master regulator of corticothalamic Layer VI identity.
            info.decoys = {'Ctip2','Rorb'}; % Uses Layer V and Layer IV markers as biological distractors.
            info.rowRange = [3 5]; % Places Layer VI cues in the lower cortical-plate band.
        elseif stage == 2 || (mode == 2 && stage == 3) % Checks for the Layer V stage.
            info.layer = 'Layer V'; % Identifies the next deep layer formed during inside-out cortical development.
            info.marker = 'Ctip2'; % Uses Ctip2 because the source identifies it as a master regulator of subcerebral projection-neuron identity.
            info.decoys = {'Tbr1','Rorb'}; % Uses Layer VI and Layer IV markers as distractors.
            info.rowRange = [6 8]; % Places Layer V cues above Layer VI in the developing cortical plate.
        elseif stage == 3 || (mode == 2 && stage == 4) % Checks for the Layer IV stage.
            info.layer = 'Layer IV'; % Identifies the main sensory-input layer in the source material.
            info.marker = 'Rorb'; % Uses Rorb because the source identifies it as a defining Layer IV marker.
            info.decoys = {'Ctip2','Cux1/2'}; % Uses Layer V and upper-layer markers as distractors.
            info.rowRange = [9 11]; % Places Layer IV above Layer V.
        elseif stage == 4 || (mode == 2 && stage == 5) % Checks for the combined superficial Layer II/III stage.
            info.layer = 'Layer II/III'; % Identifies the supragranular layers that form later in the inside-out sequence.
            info.marker = 'Cux1/2'; % Uses Cux1/Cux2 because the source identifies these genes as upper-layer identity markers.
            info.decoys = {'Rorb','Tbr1'}; % Uses Layer IV and Layer VI markers as distractors.
            info.rowRange = [12 15]; % Places superficial upper-layer cues above Layer IV.
        else % Handles the final Layer I or marginal-zone stage.
            info.layer = 'Layer I / MZ'; % Labels the superficial molecular layer that contains Cajal-Retzius cells and Reelin.
            info.marker = 'Reelin'; % Uses Reelin because the supplied material describes it as the migration-stop signal secreted in the marginal zone.
            info.decoys = {'Satb2','Fezf2'}; % Uses other cortical markers as final distractors.
            info.rowRange = [16 18]; % Places the final cue at the most superficial side of the board.
        end % Ends the stage-specific biological mapping.
    end % Ends the developmental-information helper.

    function textOut = stage_message() % Creates a short instructional message that changes with the current neuroscience milestone.
        if state.mode == 2 && state.stage == 1 % Checks whether the player is in the special tangential-entry stage for interneurons.
            textOut = 'Tangential migration: reach the cortex from the MGE/CGE side.'; % Reinforces the documented origin and tangential route of inhibitory interneurons.
        elseif state.stage == 1 || (state.mode == 2 && state.stage == 2) % Checks for Layer VI as the current developmental target.
            textOut = 'Inside-out begins deep: reach Layer VI and choose its matching marker.'; % Forces the player to connect the layer to a remembered or retrieved molecular identity.
        elseif state.stage == 2 || (state.mode == 2 && state.stage == 3) % Checks for Layer V as the current developmental target.
            textOut = 'Next is Layer V: move outward and choose the marker that fits this layer.'; % Keeps the marker relationship as an active retrieval task rather than giving away the answer.
        elseif state.stage == 3 || (state.mode == 2 && state.stage == 4) % Checks for Layer IV as the current developmental target.
            textOut = 'Sensory-layer checkpoint: reach Layer IV and identify its marker.'; % Turns the layer-marker relationship into an active gameplay decision.
        elseif state.stage == 4 || (state.mode == 2 && state.stage == 5) % Checks for the upper-layer stage.
            textOut = 'Superficial layers next: reach Layer II/III and retrieve the correct upper-layer marker.'; % Reinforces the later arrival of upper-layer neurons while making the marker a retrieval challenge.
        else % Handles the final marginal-zone stage.
            textOut = 'Final stop: Layer I / MZ - choose the cue that tells migration to stop.'; % Turns the Reelin stop-signal mechanism into the final gameplay challenge without directly naming the answer.
        end % Ends the stage-message selection.
    end % Ends the stage-message helper.

    function render_menu() % Draws the start menu and explains the two neuron modes and the core game rules.
        cla(ax); % Clears the previous screen so the menu is visually clean and separate from any prior gameplay graphics.
        axis(ax,[0 31 0 24]); % Restores the full menu coordinate range after any gameplay-specific drawing changes.
        hold(ax,'on'); % Keeps all menu text and decorative shapes in the same axes.
        inkColor = [0.16 0.24 0.42]; % Defines the single "ink" color used for every heading and emphasized label on the menu.
        inkMutedColor = [0.45 0.50 0.60]; % Defines a lighter tint of the same ink color for secondary/descriptive text, keeping the palette to one hue family instead of adding a second text color.
        accentColor = [0.16 0.48 0.52]; % Defines the single accent color used for anything selected, actionable, or emphasized (selected card, win condition, start prompt).
        accentLightColor = [0.84 0.94 0.93]; % Defines a light tint of the accent color for the selected card's fill, keeping it in the same hue family as the accent itself.
        neutralFillColor = [0.94 0.95 0.97]; % Defines the single neutral background tint shared by both info panels and any unselected card.
        neutralBorderColor = [0.78 0.81 0.88]; % Defines a darker shade of the same neutral tone for panel/card borders, so the whole menu stays within three base colors (ink, accent, neutral).
        text(15.5,22.5,'CORTICAL MAZE: INSIDE-OUT','FontName','Arial','HorizontalAlignment','center','FontSize',27,'FontWeight','bold','Color',inkColor); % Displays the playful game title prominently at the top, enlarged along with the rest of the menu text.
        text(15.5,20.9,'A cute maze about corticogenesis, migration, and cortical layering','FontName','Arial','HorizontalAlignment','center','FontSize',13,'Color',inkMutedColor); % Gives a one-line description so the scientific topic is clear before play begins.
        patch([2 29 29 2],[17.5 17.5 19.9 19.9],neutralFillColor,'EdgeColor',neutralBorderColor,'LineWidth',1); % Draws a larger, bordered information panel behind the central learning objective so it reads as the screen's visual anchor.
        text(15.5,19.15,'CORE IDEA','FontName','Arial','HorizontalAlignment','center','FontSize',14,'FontWeight','bold','Color',inkColor); % Labels the panel on its own line so the sequence below has room to be large without overflowing.
        text(15.5,18.15,'Build the cortex inside-out:   VI -> V -> IV -> II/III -> I','FontName','Arial','HorizontalAlignment','center','FontSize',15,'FontWeight','bold','Color',inkColor); % Places the key developmental sequence front and center, enlarged so it is the first rule a player absorbs, now short enough to fit on one line.
        text(15.5,16.0,'Choose your migrating neuron','FontName','Arial','HorizontalAlignment','center','FontSize',17,'FontWeight','bold','Color',inkColor); % Introduces the two distinct migration modes represented by the game.
        if state.mode == 1 % Checks whether the pyramidal mode is currently highlighted.
            patch([3 14 14 3],[11.5 11.5 15.0 15.0],accentLightColor,'EdgeColor',accentColor,'LineWidth',2); % Highlights the pyramidal choice using the single shared accent color instead of a mode-specific hue.
        else % Handles the unselected pyramidal mode.
            patch([3 14 14 3],[11.5 11.5 15.0 15.0],neutralFillColor,'EdgeColor',neutralBorderColor,'LineWidth',1); % Draws a neutral box when the pyramidal option is not active.
        end % Ends the pyramidal selection styling.
        if state.mode == 2 % Checks whether the interneuron mode is currently highlighted.
            patch([17 28 28 17],[11.5 11.5 15.0 15.0],accentLightColor,'EdgeColor',accentColor,'LineWidth',2); % Highlights the interneuron choice using the same shared accent color so selection state is the only thing color communicates.
        else % Handles the unselected interneuron mode.
            patch([17 28 28 17],[11.5 11.5 15.0 15.0],neutralFillColor,'EdgeColor',neutralBorderColor,'LineWidth',1); % Draws a neutral box when the interneuron option is not active.
        end % Ends the interneuron selection styling.
        text(8.5,14.25,'1  Pyramidal neuron','FontName','Arial','HorizontalAlignment','center','FontSize',15,'FontWeight','bold','Color',inkColor); % Labels the excitatory neuron mode.
        text(8.5,13.25,'Radial migration along a glial-like scaffold','FontName','Arial','HorizontalAlignment','center','FontSize',12,'Color',inkMutedColor); % Explains the main movement style represented by the pyramidal mode.
        text(8.5,12.35,'Starts near the ventricular zone','FontName','Arial','HorizontalAlignment','center','FontSize',11,'Color',inkMutedColor); % Links the starting position to the documented cortical progenitor zones.
        text(22.5,14.25,'2  Interneuron','FontName','Arial','HorizontalAlignment','center','FontSize',15,'FontWeight','bold','Color',inkColor); % Labels the inhibitory interneuron mode.
        text(22.5,13.25,'Tangential migration, then radial integration','FontName','Arial','HorizontalAlignment','center','FontSize',12,'Color',inkMutedColor); % Explains the two-phase migration represented in the game.
        text(22.5,12.35,'Starts from an MGE/CGE-like side zone','FontName','Arial','HorizontalAlignment','center','FontSize',11,'Color',inkMutedColor); % Connects the start region to the documented subpallial origin of interneurons.
        text(15.5,10.5,'Press 1 / 2 or LEFT / RIGHT arrow to choose, then ENTER or SPACE to begin.','FontName','Arial','HorizontalAlignment','center','FontSize',11,'Color',inkMutedColor); % Documents both selection methods now that arrow keys work on the menu, kept small as secondary guidance beneath the two cards.
        text(15.5,9.55,'CONTROLS:  Arrow keys or WASD = move   SPACE = pause   H = marker guide   Q twice = quit   ESC = menu','FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',inkMutedColor); % Compresses the control reference into one small, de-emphasized line so it no longer competes visually with the rules, and documents the new ESC-to-menu shortcut.
        patch([2 29 29 2],[2.75 2.75 8.0 8.0],neutralFillColor,'EdgeColor',neutralBorderColor,'LineWidth',1); % Gives the rules their own centered panel matching the core idea panel exactly, so the two read as a consistent pair.
        text(15.5,7.45,'RULES','FontName','Arial','HorizontalAlignment','center','FontSize',16,'FontWeight','bold','Color',inkColor); % Introduces an explicit win/lose rules section, enlarged to match the core idea's visual weight.
        text(15.5,6.4,'Move onto the ball whose marker matches the CURRENT LAYER shown in the HUD.','FontName','Arial','HorizontalAlignment','center','FontSize',13,'Color',inkMutedColor); % States the core marker-matching objective in plain language.
        text(15.5,5.4,'Correct marker: + points, advance a layer.','FontName','Arial','HorizontalAlignment','center','FontSize',13,'Color',inkMutedColor); % States the reward for a correct choice on its own short line so it never needs to shrink to fit.
        text(15.5,4.4,'Wrong marker: lose 1 of 3 lives (and points). 3 wrong picks = GAME OVER.','FontName','Arial','HorizontalAlignment','center','FontSize',13,'Color',inkMutedColor); % States the penalty and the exact loss condition together, still short enough to fit on one line at this size.
        text(15.5,3.4,'Reach Layer I / MZ with a life left = YOU WIN!','FontName','Arial','HorizontalAlignment','center','FontSize',13,'FontWeight','bold','Color',accentColor); % Spells out the win condition on its own emphasized line, using the accent color so it is unmissable without introducing a fourth color.
        text(15.5,1.85,'Press ENTER or SPACE to start','FontName','Arial','HorizontalAlignment','center','FontSize',18,'FontWeight','bold','Color',accentColor); % Gives a clear action prompt that starts the game, in the same accent color as the win condition and selected cards.
        state.phaseDirty = false; % Marks the menu as current so it is not redrawn unnecessarily until state changes again.
    end % Ends the menu-rendering function.

    function render_playfield() % Draws the static maze, cortical-layer bands, molecular cues, and cartoon neuron for the current stage.
        cla(ax); % Clears old maze graphics and old cue icons before building the new stage view.
        axis(ax,[0 31 0 24]); % Restores the full coordinate range so the HUD and maze fit together again.
        axis(ax,'equal'); % Keeps all grid cells square for spatial consistency.
        axis(ax,'off'); % Hides normal axes because the game's labels and boundaries are manually drawn.
        hold(ax,'on'); % Keeps all procedural shapes layered in a single canvas.
        draw_layer_bands(); % Paints the cortical compartments and labels them from ventricular side to marginal zone.
        draw_maze_walls(); % Draws every carved maze boundary as a soft cartoon-like line.
        if state.mode == 2 % Checks whether the player selected the interneuron mode.
            patch([0.5 4.5 4.5 0.5],[1.0 1.0 9.5 9.5],[0.93 0.87 0.96],'EdgeColor',[0.67 0.52 0.68],'LineWidth',1.2); % Tints the left strip to visually represent the MGE/CGE-like subpallial source region.
            text(2.5,8.8,'MGE/CGE','FontName','Arial','HorizontalAlignment','center','FontSize',10,'FontWeight','bold','Color',[0.49 0.34 0.51]); % Labels the source region so the tangential route has an anatomical anchor.
        end % Ends the interneuron source-zone drawing.
        text(27.4,22.6,inside_out_text(),'FontName','Arial','HorizontalAlignment','center','FontSize',10,'FontWeight','bold','Color',[0.22 0.32 0.50]); % Shows the developmental order at the top right as a compact navigation memory cue.
        text(3.7,20.8,'radial glia-like scaffold','FontName','Arial','HorizontalAlignment','center','FontSize',9,'Color',[0.34 0.50 0.58]); % Reminds the player that radial migration follows a scaffold represented by the grid pathways.
        draw_cues(); % Creates the three molecular-cue icons and their labels for the current stage.
        create_player_graphics(); % Creates the neuron body, nucleus, and migration trace graphics at the current location.
        update_hud(); % Draws the score, stage, lives, timer, and contextual message in the top HUD area.
        state.phaseDirty = false; % Marks the screen as rendered so the main loop does not rebuild static graphics on every frame.
        state.mazeDirty = false; % Marks the maze as synchronized with the current wall matrices.
    end % Ends the complete playfield-rendering function.

    function draw_layer_bands() % Paints the stacked cortical compartments so movement has a visible neurodevelopmental map rather than a generic grid.
        bands = [1 1 0.92 0.94 0.99; 2 2 0.95 0.91 0.86; 3 5 0.87 0.93 0.99; 6 8 0.91 0.88 0.97; 9 11 0.90 0.97 0.91; 12 15 0.99 0.93 0.84; 16 18 0.95 0.91 0.88]; % Defines the vertical row ranges and soft pastel colors for VZ, subplate, Layers VI, V, IV, II/III, and I/MZ.
        labels = {'VZ','Subplate (SP)','Layer VI','Layer V','Layer IV','Layer II/III','Layer I / MZ'}; % Defines the readable anatomical labels aligned with the band order in the supplied material.
        yMid = [1 2 4 7 10 13.5 17]; % Defines one vertical coordinate in each band where its label can be displayed cleanly.
        for b = 1:size(bands,1) % Iterates through every developmental compartment so each one receives a distinct pastel region.
            y1 = bands(b,1)-0.5; % Converts the first maze row of a band to the outer edge of its background rectangle.
            y2 = bands(b,2)+0.5; % Converts the last maze row of a band to the outer edge of its background rectangle.
            patch([0.5 26.5 26.5 0.5],[y1 y1 y2 y2],bands(b,3:5),'EdgeColor','none'); % Draws the full-width pastel rectangle that visually encodes cortical depth.
            text(28.1,yMid(b),labels{b},'FontName','Arial','HorizontalAlignment','center','FontSize',9,'FontWeight','bold','Color',[0.33 0.38 0.48]); % Writes the compartment label at the far right so it never blocks the maze.
        end % Ends the cortical-band drawing loop.
        line([0.5 26.5],[2.5 2.5],'Color',[0.73 0.68 0.60],'LineWidth',1.0); % Separates the transient subplate from the deeper Layer VI band with a soft boundary line.
        line([0.5 26.5],[18.5 18.5],'Color',[0.72 0.66 0.60],'LineWidth',1.2); % Closes the top edge of the Layer I/marginal-zone region for a neat cortical silhouette.
    end % Ends the cortical-layer background renderer.

    function draw_maze_walls() % Draws the maze boundaries from the vertical and horizontal wall matrices created by the generator.
        for r = 1:state.rows % Iterates over all maze rows to draw their vertical walls.
            for c = 1:state.cols-1 % Iterates over all possible separators between horizontally neighboring cells.
                if state.vWalls(r,c) == 1 % Checks whether the separator between these two cells is still a wall.
                    line([c+0.5 c+0.5],[r-0.48 r+0.48],'Color',[0.45 0.52 0.63],'LineWidth',1.3); % Draws a short wall segment using a soft blue-gray tone that stays readable without looking harsh.
                end % Ends the vertical-wall visibility check.
            end % Ends the horizontal-position loop for vertical walls.
        end % Ends the row loop for vertical walls.
        for r = 1:state.rows-1 % Iterates over all possible separators between vertically neighboring cells.
            for c = 1:state.cols % Iterates over all maze columns to draw horizontal walls.
                if state.hWalls(r,c) == 1 % Checks whether the separator between these two cells is still a wall.
                    line([c-0.48 c+0.48],[r+0.5 r+0.5],'Color',[0.45 0.52 0.63],'LineWidth',1.3); % Draws a short horizontal wall segment in the same friendly blue-gray style.
                end % Ends the horizontal-wall visibility check.
            end % Ends the column loop for horizontal walls.
        end % Ends the row loop for horizontal walls.
        if state.shortcutCount > 1 % Checks whether adaptive assistance has opened more than one shortcut.
            text(14,20.8,sprintf('plasticity shortcuts: %d',state.shortcutCount),'FontName','Arial','HorizontalAlignment','center','FontSize',8,'Color',[0.37 0.48 0.55]); % Makes the adaptive-path mechanic visible without requiring a separate tutorial panel.
        end % Ends the shortcut label check.
    end % Ends the maze-wall renderer.

    function draw_cues() % Draws the three answer choices as cheerful neuron-like molecular cue orbs.
        for k = 1:3 % Iterates over the three cue choices placed during stage construction.
            cuePalette = [0.97 0.79 0.34; 0.74 0.86 0.96; 0.91 0.77 0.91]; % Gives the three cue positions different pastel colors without making correctness itself a visual giveaway.
            col = cuePalette(k,:); % Selects the pastel color assigned to this cue position rather than to its biological correctness.
            state.cueHandles(k) = plot(state.cuePos(k,1),state.cuePos(k,2),'o','MarkerSize',22,'MarkerFaceColor',col,'MarkerEdgeColor',[0.30 0.34 0.44],'LineWidth',1.2); % Creates the round cartoon cue icon, sized to carry its own name without dominating the maze cell.
            state.cueTextHandles(k) = text(state.cuePos(k,1),state.cuePos(k,2),state.cueLabels{k},'FontName','Arial','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',7,'FontWeight','bold','Color',[0.27 0.32 0.42],'Interpreter','none'); % Writes the candidate molecular or conceptual cue label directly on top of its ball instead of floating above it.
        end % Ends the three-cue drawing loop.
    end % Ends the molecular-cue renderer.

    function pts = neuron_process_points() % Computes the current dendrite-tip and axon-tip coordinates from the player's position and last-facing heading.
        angleBack = atan2d(-state.facing(2),-state.facing(1)); % Points the dendrite fan opposite the heading, as if receiving input from where the neuron came from.
        angleFront = atan2d(state.facing(2),state.facing(1)); % Points the single axon toward the heading, as if projecting its signal onward.
        dendriteAngles = angleBack + [-60 -30 0 30 60]; % Spreads five dendrites in a fan around the back angle for a branching look.
        dendriteLengths = [0.50 0.62 0.72 0.62 0.50]; % Varies dendrite length slightly so the fan looks organic rather than a perfect symmetric star.
        pts.dendX = state.player(1) + dendriteLengths .* cosd(dendriteAngles); % Computes each dendrite tip's X coordinate from the soma center.
        pts.dendY = state.player(2) + dendriteLengths .* sind(dendriteAngles); % Computes each dendrite tip's Y coordinate from the soma center.
        pts.axonX = state.player(1) + 0.85*cosd(angleFront); % Computes the axon tip's X coordinate, longer than any single dendrite as real axons are.
        pts.axonY = state.player(2) + 0.85*sind(angleFront); % Computes the axon tip's Y coordinate, longer than any single dendrite as real axons are.
    end % Ends the neuron-geometry helper shared by graphics creation and per-frame updates.

    function create_player_graphics() % Creates the cartoon neuron body, nucleus, dendrites, axon, and short migration trail that visually follow the player.
        state.trailHandle = plot(state.trail(:,1),state.trail(:,2),'-','Color',[0.72 0.82 0.90],'LineWidth',3); % Draws a soft blue migration trace that represents the recent path rather than a permanent Snake tail.
        pts = neuron_process_points(); % Computes where the dendrites and axon should currently point given the neuron's last heading.
        state.dendriteHandles = []; % Clears any stale handles before drawing this stage's fresh dendrite set.
        for dd = 1:5 % Draws each of the five branching dendrites as a thin line from the soma center.
            state.dendriteHandles(dd) = line([state.player(1) pts.dendX(dd)],[state.player(2) pts.dendY(dd)],'Color',[0.35 0.20 0.26],'LineWidth',1.6); % Draws one dendrite segment behind where the soma will be plotted.
        end % Ends the dendrite-drawing loop.
        state.axonHandle = line([state.player(1) pts.axonX],[state.player(2) pts.axonY],'Color',[0.35 0.20 0.26],'LineWidth',1.8); % Draws the single longer axon trailing in the direction the neuron last moved.
        state.axonBulbHandle = plot(pts.axonX,pts.axonY,'o','MarkerSize',7,'MarkerFaceColor',[0.35 0.20 0.26],'MarkerEdgeColor','none'); % Adds a small axon-terminal bouton at the tip of the axon.
        state.playerHandle = plot(state.player(1),state.player(2),'o','MarkerSize',18,'MarkerFaceColor',[1.00 0.62 0.66],'MarkerEdgeColor',[0.35 0.20 0.26],'LineWidth',1.4); % Draws the main neuron body as a large pink cartoon soma on top of the dendrite/axon bases.
        state.nucleusHandle = plot(state.player(1),state.player(2),'o','MarkerSize',8,'MarkerFaceColor',[0.62 0.35 0.65],'MarkerEdgeColor','none'); % Adds a smaller purple nucleus so the player reads as a simple neuron rather than a generic cursor.
    end % Ends the player-graphics constructor.

    function update_dynamic_graphics() % Updates moving elements and lightweight HUD information without redrawing the entire maze each frame.
        if ~ishandle(fig) % Checks whether the figure still exists before attempting any graphics operations.
            state.quit = true; % Requests program termination if the player closed the window.
            return; % Leaves the update function immediately so MATLAB/Octave does not try to use deleted graphics handles.
        end % Ends the figure-existence check.
        if state.phaseDirty && strcmp(state.phase,'playing') % Checks whether a stage transition requires a complete playfield redraw.
            render_playfield(); % Rebuilds the maze, cues, and player graphics when the static scene changed.
        end % Ends the stage-redraw check.
        pts = neuron_process_points(); % Recomputes dendrite/axon tip coordinates for the neuron's current position and heading.
        for dd = 1:numel(state.dendriteHandles) % Repositions every dendrite line so the fan follows the neuron each frame.
            if ishandle(state.dendriteHandles(dd)) % Checks that this dendrite handle is still valid before updating it.
                set(state.dendriteHandles(dd),'XData',[state.player(1) pts.dendX(dd)],'YData',[state.player(2) pts.dendY(dd)]); % Moves this dendrite segment to the neuron's new position and heading.
            end % Ends the per-dendrite validity check.
        end % Ends the dendrite-update loop.
        if ~isempty(state.axonHandle) && ishandle(state.axonHandle) % Checks whether the axon line is available for a position update.
            set(state.axonHandle,'XData',[state.player(1) pts.axonX],'YData',[state.player(2) pts.axonY]); % Moves the axon line to trail from the neuron's new position in its current heading.
        end % Ends the axon-line update.
        if ~isempty(state.axonBulbHandle) && ishandle(state.axonBulbHandle) % Checks whether the axon-terminal bouton is available for a position update.
            set(state.axonBulbHandle,'XData',pts.axonX,'YData',pts.axonY); % Moves the axon terminal to match the updated axon tip.
        end % Ends the axon-bulb update.
        if ~isempty(state.playerHandle) && ishandle(state.playerHandle) % Checks whether the neuron body graphics are available for a position update.
            set(state.playerHandle,'XData',state.player(1),'YData',state.player(2)); % Moves the pink neuron soma to its new grid cell.
        end % Ends the neuron-body update.
        if ~isempty(state.nucleusHandle) && ishandle(state.nucleusHandle) % Checks whether the nucleus handle is valid for updating.
            set(state.nucleusHandle,'XData',state.player(1),'YData',state.player(2)); % Moves the purple nucleus together with the neuron soma.
        end % Ends the nucleus update.
        if ~isempty(state.trailHandle) && ishandle(state.trailHandle) % Checks whether the migration trace exists and can be refreshed.
            set(state.trailHandle,'XData',state.trail(:,1),'YData',state.trail(:,2)); % Updates the fading route so it records only the most recent path and never behaves like a fixed Snake tail.
        end % Ends the trail update.
        update_hud(); % Refreshes score, lives, stage, timer, and short feedback text so the interface always matches the state.
    end % Ends the dynamic graphics updater.

    function update_hud() % Updates the compact upper status panel and the optional timed memory aid.
        if ~isempty(state.hudHandles) % Checks whether a previous HUD exists so its text can be replaced instead of duplicated.
            valid = false(size(state.hudHandles)); % Creates a validity mask for the existing text handles because a complete stage redraw can delete them.
            for q = 1:numel(state.hudHandles) % Iterates through the stored HUD handles and checks each one individually for graphics validity.
                valid(q) = ishandle(state.hudHandles(q)); % Records whether that specific HUD text object still exists.
            end % Ends the HUD-handle validity loop.
            if all(valid) % Checks whether every stored HUD element is still valid and therefore safe to update in place.
                totalTime = toc(state.gameClock); % Reads the total game time for the live timer display.
                modeName = 'Pyramidal / radial'; % Sets the default mode label for the HUD.
                if state.mode == 2 % Checks whether the player selected the interneuron mode.
                    modeName = 'Interneuron / tangential -> radial'; % Updates the label so the mode itself becomes part of the ongoing learning cue.
                end % Ends the mode-name selection.
                set(state.hudHandles(1),'String',sprintf('Score: %d',state.score)); % Updates the live score value.
                set(state.hudHandles(2),'String',sprintf('Lives: %d',state.lives)); % Updates the remaining-life counter.
                set(state.hudHandles(3),'String',sprintf('Time: %4.1f s',totalTime)); % Updates the elapsed-time display with one decimal place for arcade-style feedback.
                set(state.hudHandles(4),'String',sprintf('Stage %d/%d: %s',state.stage,total_stages(),state.targetInfo.layer)); % Keeps the stage count and biological layer label aligned in a compact HUD string.
            end % Ends the valid-HUD update branch.
        end % Ends the existing-HUD check.
        if isempty(state.hudHandles) || ~all(arrayfun(@(h) ishandle(h),state.hudHandles)) % Checks whether the HUD has not yet been created or was removed by a screen redraw.
            totalTime = toc(state.gameClock); % Reads the timer for the initial HUD construction.
            modeName = 'Pyramidal / radial'; % Sets the default displayed mode label before checking the actual selection.
            if state.mode == 2 % Checks whether the player selected the interneuron mode.
                modeName = 'Interneuron / tangential -> radial'; % Uses a compact summary of the two migration phases.
            end % Ends the mode-name selection for first-time HUD construction.
            state.hudHandles(1) = text(7.0,22.55,sprintf('Score: %d',state.score),'FontName','Arial','HorizontalAlignment','left','FontSize',11,'FontWeight','bold','Color',[0.23 0.31 0.44]); % Creates the score label in the top-left HUD area.
            state.hudHandles(2) = text(7.0,21.75,sprintf('Lives: %d',state.lives),'FontName','Arial','HorizontalAlignment','left','FontSize',10,'Color',[0.40 0.31 0.40]); % Creates the lives label directly beneath the score.
            state.hudHandles(3) = text(12.0,22.55,sprintf('Time: %4.1f s',totalTime),'FontName','Arial','HorizontalAlignment','left','FontSize',10,'Color',[0.30 0.37 0.47]); % Creates the timer label in the center-left HUD area.
            state.hudHandles(4) = text(12.0,21.75,sprintf('Stage %d/%d: %s',state.stage,total_stages(),state.targetInfo.layer),'FontName','Arial','HorizontalAlignment','left','FontSize',10,'FontWeight','bold','Color',[0.30 0.37 0.47]); % Creates the developmental-stage label used throughout play.
            state.hudHandles(5) = text(20.0,22.55,modeName,'FontName','Arial','HorizontalAlignment','left','FontSize',9,'Color',[0.40 0.45 0.54]); % Creates the migration-mode label that keeps the behavioral rule visible without interrupting play.
            state.hudHandles(6) = text(20.0,21.75,'H = memory guide','FontName','Arial','HorizontalAlignment','left','FontSize',9,'Color',[0.42 0.45 0.52]); % Reminds the player that help is available but deliberately optional.
            state.hudHandles(7) = text(3.5,20.55,'','FontName','Arial','HorizontalAlignment','center','FontSize',10,'FontWeight','bold','Color',[0.26 0.35 0.49]); % Creates an empty message slot directly above the maze where temporary feedback can appear.
        end % Ends the HUD-creation check.
        if ~isempty(state.hudHandles) && all(arrayfun(@(h) ishandle(h),state.hudHandles)) % Checks that all HUD objects exist before applying the latest text values.
            set(state.hudHandles(4),'String',sprintf('Stage %d/%d: %s',state.stage,total_stages(),state.targetInfo.layer)); % Refreshes the stage number and current layer label after every movement.
            set(state.hudHandles(1),'String',sprintf('Score: %d',state.score)); % Refreshes the score after every reward or penalty.
            set(state.hudHandles(2),'String',sprintf('Lives: %d',state.lives)); % Refreshes the life count after any conceptual error.
            set(state.hudHandles(3),'String',sprintf('Time: %4.1f s',toc(state.gameClock))); % Refreshes the timer so the screen feels alive even while the neuron is not moving.
            if ~isempty(state.hudHandles(7)) && ishandle(state.hudHandles(7)) % Checks whether the message slot is still valid before updating it.
                currentTime = toc(state.gameClock); % Reads the current game time to decide whether temporary text should still be visible.
                if state.paused % Checks whether the game is currently paused.
                    set(state.hudHandles(7),'String','PAUSED - press SPACE to resume.'); % Makes the paused state impossible to miss.
                elseif currentTime <= state.messageUntil % Checks whether the latest contextual message is still within its display period.
                    set(state.hudHandles(7),'String',state.message); % Displays the active feedback message such as a correct cue, wrong cue, or stage transition.
                else % Handles the normal state when no temporary message is active.
                    set(state.hudHandles(7),'String',''); % Keeps the upper center visually uncluttered when no message is needed.
                end % Ends the message-display decision.
            end % Ends the HUD-message validity check.
        end % Ends the final HUD update branch.
        if state.showGuide && toc(state.gameClock) < state.guideUntil % Checks whether the short working-memory guide should currently be visible.
            if isempty(state.helpHandles) || ~all(arrayfun(@(h) ishandle(h),state.helpHandles)) % Prevents the guide from being redrawn every animation frame and instead draws it only when needed.
                render_guide(); % Draws the temporary marker mapping so the player can refresh memory without leaving the maze.
            end % Ends the one-time guide-render check.
        elseif state.showGuide % Handles the moment when the guide's timer has just expired.
            state.showGuide = false; % Hides the guide on the next update so the help remains intentionally temporary.
            clear_guide(); % Removes the guide text objects from the axes.
        end % Ends the field-guide visibility logic.
    end % Ends the HUD updater.

    function render_guide() % Draws a compact three-second field guide that supports memory retrieval without permanently revealing every answer.
        clear_guide(); % Clears any previous version so the guide can be redrawn cleanly after a new H press.
        state.helpHandles(1) = patch([2.0 11.0 11.0 2.0],[3.0 3.0 18.0 18.0],[0.99 0.98 0.92],'EdgeColor',[0.76 0.66 0.40],'LineWidth',1.2); % Stores the memory-card background so it can be deleted cleanly when the three-second aid expires.
        state.helpHandles(2) = text(6.5,17.2,'MEMORY GUIDE','FontName','Arial','HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color',[0.39 0.33 0.20]); % Stores the guide title as a temporary graphics handle.
        state.helpHandles(3) = text(6.5,15.7,'VI  ->  Tbr1','FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.32 0.36 0.44]); % Stores the Layer VI mapping derived from the supplied source.
        state.helpHandles(4) = text(6.5,14.3,'V   ->  Ctip2','FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.32 0.36 0.44]); % Stores the Layer V mapping from the supplied source.
        state.helpHandles(5) = text(6.5,12.9,'IV  ->  Rorb','FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.32 0.36 0.44]); % Stores the Layer IV mapping from the supplied source.
        state.helpHandles(6) = text(6.5,11.5,'II/III -> Cux1/2','FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.32 0.36 0.44]); % Stores the upper-layer mapping from the supplied source.
        state.helpHandles(7) = text(6.5,10.1,'I/MZ -> Reelin','FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.32 0.36 0.44]); % Stores the marginal-zone Reelin mapping from the supplied source.
        state.helpHandles(8) = text(6.5,7.6,'Press H again to refresh','FontName','Arial','HorizontalAlignment','center','FontSize',8,'Color',[0.46 0.42 0.34]); % Stores the reminder that the memory support is temporary.
        state.helpHandles(9) = text(6.5,6.5,'Guide use costs 3 points','FontName','Arial','HorizontalAlignment','center','FontSize',8,'Color',[0.55 0.45 0.32]); % Stores the reminder that externalizing the memory has a small strategic cost.
    end % Ends the field-guide renderer.

    function clear_guide() % Deletes the temporary field-guide text and panel so the maze becomes the main focus again.
        for q = 1:numel(state.helpHandles) % Iterates through every temporary help graphic recorded in the state.
            if ishandle(state.helpHandles(q)) % Checks whether the specific help object still exists before deleting it.
                delete(state.helpHandles(q)); % Removes that guide object from the axes.
            end % Ends the individual help-object validity check.
        end % Ends the guide-object deletion loop.
        state.helpHandles = []; % Clears the stored handle list so the next guide display starts fresh.
    end % Ends the guide-clearing helper.

    function step_game() % Advances the neuron by one grid cell and resolves walls, route preferences, cue collection, score, and stage changes.
        if state.paused || state.gameOver % Stops all movement logic when the player has deliberately paused or the game has ended.
            return; % Leaves the function immediately so paused/end states remain stable until a key action changes them.
        end % Ends the movement-guard check.
        if all(state.direction == 0) % Stops repeated bumps once the neuron has already been halted at a wall or boundary.
            return; % Leaves the function immediately since there is no direction to move in.
        end % Ends the no-direction guard.
        nextPos = state.player + state.direction; % Computes the candidate next cell from the current position and selected direction.
        if nextPos(1) < 1 || nextPos(1) > state.cols || nextPos(2) < 1 || nextPos(2) > state.rows % Checks whether the candidate would leave the playable grid boundary.
            state.score = max(0,state.score - 1); % Applies a tiny score penalty for trying to move outside the cortex-like board.
            state.message = 'Boundary bump - stay inside the developing cortex.'; % Provides immediate spatial feedback rather than silently ignoring the input.
            state.messageUntil = toc(state.gameClock) + 0.8; % Shows the boundary feedback briefly so it does not become distracting.
            state.direction = [0 0]; % Halts automatic movement so the boundary bump does not repeat every tick.
            return; % Rejects the invalid move without changing the neuron position.
        end % Ends the boundary check.
        if blocked_by_wall(state.player,nextPos) % Checks whether the requested movement is blocked by the current maze wall structure.
            state.wallBumps = state.wallBumps + 1; % Records the blocked attempt for end-of-run statistics and self-evaluation.
            state.score = max(0,state.score - 1); % Applies a small non-catastrophic penalty so exploratory navigation remains possible.
            state.message = 'Wall bump - try a different pathway.'; % Encourages route planning instead of rewarding brute-force movement.
            state.messageUntil = toc(state.gameClock) + 0.8; % Displays the hint briefly so the HUD remains readable.
            state.direction = [0 0]; % Halts automatic movement so the wall bump does not repeat every tick.
            return; % Cancels the blocked move and leaves the neuron in its current cell.
        end % Ends the maze-wall collision check.
        state.player = nextPos; % Commits the movement so the neuron enters the chosen neighboring cell.
        state.moves = state.moves + 1; % Increments the total movement count used for performance statistics.
        state.stageMoves = state.stageMoves + 1; % Increments the stage-specific movement count used to tune adaptive shortcuts.
        state.trail = [state.trail; state.player]; % Appends the new position to the migration trace so the route is visible as a short neural memory.
        if size(state.trail,1) > 9 % Checks whether the migration trace has grown beyond the intended short memory length.
            state.trail = state.trail(end-8:end,:); % Keeps only the newest nine positions so the trace remains a recent-path visualization rather than a permanent Snake body.
        end % Ends the trail-length limit.
        routeBonus = route_preference_bonus(); % Computes a tiny reward for movement that matches the biologically motivated preferred migration direction.
        state.score = state.score + routeBonus; % Adds the route-fidelity bonus to the current score.
        cueIndex = cue_at_player(); % Checks whether the new cell contains one of the three molecular or conceptual cue choices.
        if cueIndex > 0 % Handles the case in which the player has reached a cue icon.
            if cueIndex == state.correctCue % Checks whether the chosen cue matches the stage's correct biological answer.
                handle_correct_cue(); % Processes the reward, streak, efficiency bonus, and transition to the next developmental stage.
            else % Handles an incorrect molecular or conceptual choice.
                handle_wrong_cue(cueIndex); % Applies the life and score penalty while keeping the stage active for another attempt.
            end % Ends the correct-versus-wrong cue branch.
        end % Ends the cue-collision check.
    end % Ends the one-cell game-step function.

    function blocked = blocked_by_wall(a,b) % Determines whether two neighboring cells are separated by a maze wall.
        blocked = true; % Defaults to blocked so an unexpected coordinate combination fails safely rather than allowing illegal movement.
        if a(1) == b(1) && a(2) + 1 == b(2) % Checks whether the move is upward by one row in the coordinate convention used by the game.
            blocked = state.hWalls(a(2),a(1)) == 1; % Reads the horizontal wall separating the lower and upper cells.
        elseif a(1) == b(1) && a(2) - 1 == b(2) % Checks whether the move is downward by one row.
            blocked = state.hWalls(b(2),a(1)) == 1; % Reads the horizontal wall separating the upper and lower cells.
        elseif a(2) == b(2) && a(1) + 1 == b(1) % Checks whether the move is rightward by one column.
            blocked = state.vWalls(a(2),a(1)) == 1; % Reads the vertical wall separating the left and right cells.
        elseif a(2) == b(2) && a(1) - 1 == b(1) % Checks whether the move is leftward by one column.
            blocked = state.vWalls(a(2),b(1)) == 1; % Reads the vertical wall separating the right and left cells.
        end % Ends the direction-specific wall lookup.
    end % Ends the maze-collision helper.

    function bonus = route_preference_bonus() % Rewards movement that resembles the chosen neuron's experimentally motivated migration style.
        bonus = 0; % Starts with no movement-style bonus so ordinary maze exploration remains neutral.
        vertical = abs(state.direction(2)) == 1; % Detects whether the latest movement was vertical, which is the radial component in this grid representation.
        horizontal = abs(state.direction(1)) == 1; % Detects whether the latest movement was horizontal, which is the tangential component in this grid representation.
        if state.mode == 1 && vertical % Checks whether a pyramidal neuron made the movement expected from radial migration.
            bonus = 1; % Rewards radial-like vertical motion with a small point so the concept becomes mechanically meaningful.
        elseif state.mode == 2 && state.stage == 1 && horizontal % Checks whether an interneuron is still in the tangential-entry stage and moved horizontally.
            bonus = 1; % Rewards the documented tangential phase with a small point.
        elseif state.mode == 2 && state.stage > 1 && vertical % Checks whether an interneuron has entered the cortex and is now making radial-like motion.
            bonus = 1; % Rewards the transition to radial integration after tangential entry.
        end % Ends the migration-style reward logic.
    end % Ends the route-preference helper.

    function idx = cue_at_player() % Returns which cue, if any, currently occupies the player's cell.
        idx = 0; % Uses zero to represent no cue collision so the calling function can distinguish it from cue indices one through three.
        for q = 1:3 % Checks every currently active cue against the player's position.
            if all(state.player == state.cuePos(q,:)) % Tests whether the player's exact grid coordinate matches the cue's coordinate.
                idx = q; % Returns that cue index immediately because grid cells cannot contain multiple cues.
                return; % Leaves the search as soon as a collision has been found.
            end % Ends the coordinate-match check for the current cue.
        end % Ends the search through all cue choices.
    end % Ends the cue-collision helper.

    function handle_correct_cue() % Rewards the player for selecting the biologically correct cue and advances the developmental program.
        elapsed = toc(state.stageClock); % Measures how long the player needed to solve the current developmental stage.
        speedBonus = max(0,25-floor(elapsed)); % Converts fast correct choices into a modest speed bonus while avoiding negative bonuses.
        efficiencyBonus = max(0,20-floor(state.stageMoves/3)); % Rewards economical routes without making absolute shortest-path solving mandatory.
        reward = 40 + speedBonus + efficiencyBonus; % Combines a large conceptual reward with smaller efficiency and speed bonuses.
        state.score = state.score + reward; % Adds the full reward to the player's running score.
        state.streak = state.streak + 1; % Extends the correct-cue streak as a behavioral reward-prediction-like feedback signal.
        state.bestStreak = max(state.bestStreak,state.streak); % Stores the best streak reached in the session for the end screen.
        state.message = sprintf('Correct cue! +%d points - migration stage completed.',reward); % Gives explicit positive feedback that links the answer to stage completion.
        state.messageUntil = toc(state.gameClock) + 1.8; % Keeps the positive feedback visible long enough to be emotionally and educationally salient.
        state.assistLevel = adapt_difficulty(); % Updates the number of next-stage shortcuts based on how the player performed.
        if state.stage >= total_stages() % Checks whether the final developmental milestone has now been completed.
            state.gameOver = true; % Marks the run as complete so no further movement is processed.
            state.phase = 'end'; % Switches to the results screen for the win condition.
            state.running = false; % Marks the active movement loop as finished for clarity.
            state.phaseDirty = true; % Requests a final results-screen render.
        else % Handles the common case where more developmental milestones remain.
            state.stage = state.stage + 1; % Advances from the completed cortical stage to the next inside-out milestone.
            state.phaseDirty = true; % Requests a new maze and cue layout for the next developmental stage.
            build_stage(); % Regenerates the pathways and cue puzzle, making the maze itself change as learning progresses.
        end % Ends the final-stage versus next-stage decision.
    end % Ends the correct-cue reward function.

    function handle_wrong_cue(~) % Penalizes an incorrect molecular cue choice while keeping the player alive long enough to learn from the mistake.
        state.wrongCues = state.wrongCues + 1; % Records the conceptual error for later feedback and adaptive-difficulty decisions.
        state.lives = state.lives - 1; % Removes one mistake token because the selected marker was biologically mismatched to the current layer.
        state.score = max(0,state.score - 20); % Applies a noticeable but recoverable score penalty for the wrong concept.
        state.streak = 0; % Resets the correct-cue streak because a wrong answer breaks the current reinforcement sequence.
        state.message = sprintf('Not the right cue for %s - one life lost.',state.targetInfo.layer); % Explains the consequence while naming the layer being learned.
        state.messageUntil = toc(state.gameClock) + 1.6; % Keeps the corrective feedback visible long enough to reinforce the mistake without freezing play.
        if state.lives <= 0 % Checks whether the player has used all available mistake tokens.
            state.gameOver = true; % Marks the run as lost so further movement is disabled.
            state.phase = 'end'; % Switches to the results screen for the lose condition.
            state.running = false; % Stops the active game loop after the loss.
            state.phaseDirty = true; % Requests the results screen to be rendered.
        else % Handles the common case where at least one life remains.
            place_replacement_cue(); % Moves the incorrect cue elsewhere in the same target band so the player gets another opportunity to retrieve the correct answer.
        end % Ends the game-over versus continue branch.
    end % Ends the wrong-cue handler.

    function place_replacement_cue() % Relocates a previously chosen cue so incorrect choices do not remain permanently sitting under the neuron.
        cueToMove = randi(3); % Randomly selects which cue icon should be moved so there is no fixed penalty location.
        info = state.targetInfo; % Retrieves the current target information needed to keep the replacement in the correct anatomical region.
        rows = info.rowRange; % Reads the valid cortical band for the current stage.
        candidate = [randi(state.cols) rows(randi(numel(rows)))]; % Chooses a new random cell inside the target band.
        while any(all(state.cuePos == candidate,2)) || all(candidate == round(state.player)) % Rejects any location already occupied by another cue or the player.
            candidate = [randi(state.cols) rows(randi(numel(rows)))]; % Draws another candidate until a free cell is found.
        end % Ends the replacement-position search.
        state.cuePos(cueToMove,:) = candidate; % Commits the cue relocation so the stage puzzle remains spatially dynamic after a mistake.
        if cueToMove <= numel(state.cueHandles) && ishandle(state.cueHandles(cueToMove)) % Checks whether the corresponding cue icon still exists before moving it.
            set(state.cueHandles(cueToMove),'XData',candidate(1),'YData',candidate(2)); % Moves the visual cue icon to its new cell.
        end % Ends the cue-icon move check.
        if cueToMove <= numel(state.cueTextHandles) && ishandle(state.cueTextHandles(cueToMove)) % Checks whether the cue label text object still exists before moving it.
            set(state.cueTextHandles(cueToMove),'Position',[candidate(1) candidate(2)]); % Moves the cue label onto its relocated ball so the name stays written directly on the marker.
        end % Ends the cue-label move check.
    end % Ends the replacement-cue helper.

    function newAssist = adapt_difficulty() % Adjusts future maze support from the player's current stage performance to mimic adaptive learning.
        elapsed = toc(state.stageClock); % Reads the current stage time so quick and slow performance can be distinguished.
        if state.stageMoves > 35 || elapsed > 25 || state.wrongCues >= state.stage % Checks whether the player needed substantial effort or accumulated multiple mistakes.
            newAssist = min(4,state.assistLevel + 1); % Adds one more shortcut next stage while capping assistance to preserve a genuine puzzle.
            return; % Exits immediately because the difficult-performance branch has already chosen the next support level.
        end % Ends the struggling-performance test.
        if state.stageMoves < 16 && state.streak >= 2 % Checks whether the player is both fast and consistently correct.
            newAssist = max(0,state.assistLevel - 1); % Removes one shortcut so successful performance causes the maze to tighten gradually.
        else % Handles average performance that should not strongly change difficulty.
            newAssist = state.assistLevel; % Keeps the current number of shortcuts when performance is neither clearly weak nor clearly strong.
        end % Ends the adaptive-assistance decision.
    end % Ends the adaptive-difficulty function.

    function n = total_stages() % Returns the number of developmental stages required for the currently selected neuron type.
        if state.mode == 1 % Checks whether the player is controlling a pyramidal neuron.
            n = 5; % Uses five milestones: VI, V, IV, II/III, and I/MZ.
        else % Handles the interneuron mode.
            n = 6; % Adds one tangential cortical-entry milestone before the same five layer milestones.
        end % Ends the mode-dependent stage-count selection.
    end % Ends the stage-count helper.

    function txt = inside_out_text() % Returns a compact top-right reminder of the developmental order represented by the game.
        txt = 'Inside-out: VI -> V -> IV -> II/III -> I'; % Encodes the source's ordering in plain ASCII text for reliable cross-platform rendering.
    end % Ends the inside-out label helper.

    function render_end_screen() % Draws the final win/lose screen with a clear outcome and a small reflective statistics summary.
        cla(ax); % Clears the last gameplay frame so the result screen is uncluttered.
        axis(ax,[0 31 0 24]); % Restores the full screen coordinate system used by the menu and HUD.
        hold(ax,'on'); % Keeps decorative shapes and result text on the same canvas.
        totalTime = toc(state.gameClock); % Reads the total duration of the completed or failed run.
        won = state.lives > 0 && state.stage >= total_stages(); % Determines whether the final state satisfies the game's win condition.
        if won % Checks whether the player successfully completed the entire developmental sequence.
            patch([5 26 26 5],[13 13 20.5 20.5],[0.85 0.95 0.90],'EdgeColor',[0.35 0.60 0.48],'LineWidth',2); % Draws a soft green victory panel behind the congratulations message.
            text(15.5,18.2,'CORTICAL LAMINATION COMPLETE!','FontName','Arial','HorizontalAlignment','center','FontSize',20,'FontWeight','bold','Color',[0.20 0.48 0.35]); % Announces successful completion using the game's biological metaphor.
            text(15.5,16.7,'Your neuron reached the correct developmental sequence and stopped at the marginal zone.','FontName','Arial','HorizontalAlignment','center','FontSize',11,'Color',[0.28 0.40 0.34]); % Explains the final outcome in terms of the represented migration process.
        else % Handles the lose condition when the player selected too many incorrect cues.
            patch([5 26 26 5],[13 13 20.5 20.5],[0.98 0.90 0.92],'EdgeColor',[0.67 0.43 0.48],'LineWidth',2); % Draws a soft rose panel behind the corrective result message.
            text(15.5,18.2,'MIGRATION PAUSED','FontName','Arial','HorizontalAlignment','center','FontSize',20,'FontWeight','bold','Color',[0.60 0.27 0.34]); % Announces that the neuron failed the current developmental run without framing the mistake as permanent.
            text(15.5,16.7,'Try again and use the molecular-marker relationships to make each stage easier.','FontName','Arial','HorizontalAlignment','center','FontSize',11,'Color',[0.48 0.35 0.39]); % Frames the loss as an opportunity for another learning attempt.
        end % Ends the win-versus-loss visual branch.
        text(15.5,11.5,sprintf('Score: %d',state.score),'FontName','Arial','HorizontalAlignment','center','FontSize',16,'FontWeight','bold','Color',[0.25 0.31 0.42]); % Reports the final score prominently.
        text(15.5,10.1,sprintf('Time: %4.1f s    Moves: %d    Wall bumps: %d',totalTime,state.moves,state.wallBumps),'FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.36 0.40 0.50]); % Reports navigation efficiency and route-planning statistics.
        text(15.5,8.8,sprintf('Wrong cues: %d    Best correct streak: %d',state.wrongCues,state.bestStreak),'FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.36 0.40 0.50]); % Reports conceptual accuracy and reinforcement-style streak performance.
        text(15.5,6.4,'What the mechanics taught: deep layers first, then outward; migration style changes by neuron type; Reelin ends radial migration.','FontName','Arial','HorizontalAlignment','center','FontSize',10,'Color',[0.30 0.36 0.47]); % Summarizes the conceptual lessons without turning the entire game into a lecture.
        text(15.5,4.25,'R / ENTER / SPACE = restart     M / ESC = menu     Q = quit','FontName','Arial','HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color',[0.24 0.43 0.57]); % Gives clear next-step controls so the game never leaves the player at a dead end.
        text(15.5,2.35,'The maze was procedurally generated from simple grid walls, shapes, and text only.','FontName','Arial','HorizontalAlignment','center','FontSize',9,'Color',[0.49 0.52 0.58]); % Confirms the procedural-graphics requirement in the final presentation screen.
        state.phaseDirty = false; % Marks the results screen as rendered so it does not redraw every frame.
    end % Ends the final result-screen renderer.
end % Ends the main cortical-maze game function.
