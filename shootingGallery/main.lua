
-- run at the moment the game starts
function love.load()
    lg = love.graphics;

    target = {};
    target.x = 300;
    target.y = 300;
    target.radius = 50;

    score = 0;
    timer = 0;
    gameState = 1;

    gameFont = lg.newFont(40);

    sprites = {}
    sprites.sky = lg.newImage('sprites/sky.png');
    sprites.crosshairs = lg.newImage('sprites/crosshairs.png');
    sprites.target = lg.newImage('sprites/target.png');

    love.mouse.setVisible(false);
end

-- the game loop
-- called every frame
-- for 60fps (love default fps), it will run 60 times every second
function love.update(dt)
    if timer > 0 then
        timer = timer - dt;
    end

    if timer < 0 then
        timer = 0;
        gameState = 1;
    end
end

-- drawing graphics to the screen
-- similar to update, runs every second similar to update
-- but it's only related to graphics and what the user sees
-- important code should not stay in this function
function love.draw()
    -- background
    lg.draw(sprites.sky, 0, 0);

    -- score
    lg.setColor(1, 1, 1);
    lg.setFont(gameFont);
    lg.print('Score: ' .. score, 5, 5);

    -- timer
    lg.print('Time: ' .. math.ceil(timer), 300, 5);

    -- start message
    if gameState == 1 then
        lg.printf('Click anywhere to begin!', 0, 250, lg.getWidth(), 'center');
    end

    if gameState == 2 then
        -- target
        lg.draw(sprites.target, target.x - target.radius, target.y - target.radius);
    end
    
    -- crosshairs
    -- -20 because the crosshairs img is 40x40px
    lg.draw(sprites.crosshairs, love.mouse.getX() - 20, love.mouse.getY() - 20);
end

function love.mousepressed(x, y, button, isTouch, presses)
    if button == 1 and gameState == 2 then
        local mouseToTarget = distanceBetween(x, y, target.x, target.y);

        if mouseToTarget < target.radius then
            score = score + 1;
            target.x = math.random(target.radius, lg.getWidth() - target.radius);
            target.y = math.random(target.radius, lg.getHeight() - target.radius);
        else
            score = score - 1;
        end
    elseif button == 1 and gameState == 1 then
        gameState = 2;
        timer = 10;
        score = 0;
    end
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end