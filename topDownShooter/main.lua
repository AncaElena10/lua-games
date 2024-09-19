function love.load()
    -- avoid using the same randoms eveytime the game starts
    -- use the current time as the unique value
    math.randomseed(os.time());

    myFont = love.graphics.newFont(30);

    sprites = {};
    sprites.background = love.graphics.newImage('sprites/background.png');
    sprites.bullet = love.graphics.newImage('sprites/bullet.png');
    sprites.player = love.graphics.newImage('sprites/player.png');
    sprites.zombie = love.graphics.newImage('sprites/zombie.png');

    player = {};
    player.x = love.graphics.getWidth() / 2;
    player.y = love.graphics.getHeight() / 2;
    player.speed = 3 * 60; -- * 60 fps

    zombies = {};

    bullets = {};

    gameState = 1;
    score = 0;
    maxTime = 2;
    timer = maxTime;
end

function love.update(dt)
    playerMovement(dt);
    enemyMovement(dt);
    bulletMovement(dt);
    removeBulletsOutOfBounds();
    detectZombieBulletCollision();
    removeZombieAndBulletOnCollision();
    spawnZombieOnTime(dt);
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0);

    if (gameState == 1) then
        love.graphics.setFont(myFont);
        love.graphics.printf('Click anywhere to begin!', 0, 50, love.graphics.getWidth(), 'center');
    end

    love.graphics.printf('Score: ' .. score, 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), 'center');

    local playerRotation = playerAngle();
    love.graphics.draw(sprites.player, player.x, player.y, playerRotation, nil, nil, sprites.player:getWidth() / 2,
        sprites.player:getHeight() / 2);

    for i, z in ipairs(zombies) do
        local zombieRotation = zombieAngle(z);
        love.graphics.draw(sprites.zombie, z.x, z.y, zombieRotation, nil, nil, sprites.zombie:getWidth() / 2,
            sprites.zombie:getHeight() / 2);
    end

    for i, b in ipairs(bullets) do
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, nil, sprites.bullet:getWidth() / 2,
            sprites.bullet:getHeight() / 2);
    end
end

function playerMovement(dt)
    if (gameState == 2) then
        if (love.keyboard.isDown('d') and player.x < love.graphics.getWidth()) then
            player.x = player.x + player.speed * dt;
        end

        if (love.keyboard.isDown('a') and player.x > 0) then
            player.x = player.x - player.speed * dt;
        end

        if (love.keyboard.isDown('w') and player.y > 0) then
            player.y = player.y - player.speed * dt;
        end

        if (love.keyboard.isDown('s') and player.y < love.graphics.getHeight()) then
            player.y = player.y + player.speed * dt;
        end
    end
end

function enemyMovement(dt)
    for i, z in ipairs(zombies) do
        local zombieRotation = zombieAngle(z);

        z.x = z.x + math.cos(zombieRotation) * z.speed * dt;
        z.y = z.y + math.sin(zombieRotation) * z.speed * dt;

        -- check collision
        local distance = distanceBetween(z.x, z.y, player.x, player.y);
        if (distance < 30) then
            for i, z in ipairs(zombies) do
                zombies[i] = nil;

                -- reset game
                gameState = 1;

                -- reset player position
                player.x = love.graphics.getWidth() / 2;
                player.y = love.graphics.getHeight() / 2;
            end
        end
    end
end

function bulletMovement(dt)
    for i, b in ipairs(bullets) do
        b.x = b.x + math.cos(b.direction) * b.speed * dt;
        b.y = b.y + math.sin(b.direction) * b.speed * dt;
    end
end

function removeBulletsOutOfBounds()
    -- going backwards and remove the first one (because by default the last one is removed)
    for i = #bullets, 1, -1 do
        local currentBullet = bullets[i];
        if (currentBullet.x < 0 or currentBullet.y < 0 or currentBullet.x > love.graphics.getWidth() or currentBullet.y > love.graphics.getHeight()) then
            table.remove(bullets, i);
        end
    end
end

function detectZombieBulletCollision()
    for i, z in ipairs(zombies) do
        for j, b in ipairs(bullets) do
            local distance = distanceBetween(z.x, z.y, b.x, b.y);
            if (distance < 20) then
                z.gone = true;
                b.gone = true;
                score = score + 1;
            end
        end
    end
end

function removeZombieAndBulletOnCollision()
    for i = #zombies, 1, -1 do
        local currentZombie = zombies[i];
        if (currentZombie.gone == true) then
            table.remove(zombies, i);
        end
    end

    for i = #bullets, 1, -1 do
        local currentBullet = bullets[i];
        if (currentBullet.gone == true) then
            table.remove(bullets, i);
        end
    end
end

function spawnZombieOnTime(dt)
    if (gameState == 2) then
        -- spawn zombie every 2s
        timer = timer - dt;

        if (timer <= 0) then
            spawnZombie();
            maxTime = 0.95 * maxTime; -- decrease maxTime to spawn enemies faster
            timer = maxTime;
        end
    end
end

function playerAngle()
    return math.atan2(-player.y + love.mouse.getY(), -player.x + love.mouse.getX());
end

function zombieAngle(enemy)
    return math.atan2(player.y - enemy.y, player.x - enemy.x);
end

function spawnZombie()
    local zombie = {};

    zombie.x = 0;
    zombie.y = 0;
    zombie.speed = 140;
    zombie.gone = false;

    -- choose a random side of the screen
    local side = math.random(1, 4);
    local buffer = 30;

    -- give the enemy a buffer and spawn it a bit outside of the screen
    if (side == 1) then
        -- left
        zombie.x = -buffer;
        zombie.y = math.random(0, love.graphics.getHeight());
    elseif (side == 2) then
        -- right
        zombie.x = love.graphics.getWidth() + buffer;
        zombie.y = math.random(0, love.graphics.getHeight());
    elseif (side == 3) then
        -- top
        zombie.x = math.random(0, love.graphics.getWidth());
        zombie.y = -buffer;
    elseif (side == 4) then
        -- bottom
        zombie.x = math.random(0, love.graphics.getWidth());
        zombie.y = love.graphics.getHeight() + buffer;
    end

    table.insert(zombies, zombie);
end

function love.keypressed(key)
    if (key == 'space') then
        spawnZombie();
    end
end

function love.mousepressed(x, y, button)
    if (button == 1 and gameState == 2) then
        spawnBullet();
    elseif (button == 1 and gameState == 1) then
        -- reset everything
        gameState = 2;
        maxTime = 2;
        timer = maxTime;
        score = 0;
    end
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2);
end

function spawnBullet()
    local bullet = {};
    bullet.x = player.x;
    bullet.y = player.y;
    bullet.speed = 500;
    bullet.direction = playerAngle();
    bullet.gone = false;

    table.insert(bullets, bullet);
end
