function love.load()
    love.window.setMode(1000, 768);

    anim8 = require 'libraries.anim8.anim8';
    sti = require 'libraries.Simple-Tiled-Implementation.sti';
    cameraFile = require 'libraries.hump.camera';

    cam = cameraFile();

    sounds = {}
    sounds.jump = love.audio.newSource('audio/jump.wav', 'static');
    sounds.env = love.audio.newSource('audio/music.mp3', 'stream');

    -- environmental music - keep looping
    sounds.env:setLooping(true);
    sounds.env:setVolume(0.1);
    sounds.env:play();

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png');
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png');
    sprites.background = love.graphics.newImage('sprites/background.png');

    -- the sprite has 15 columns and 3 rows - 9210 × 1692
    -- each picture will have these sizes:
    local grid = anim8.newGrid(
        sprites.playerSheet:getWidth() / 15, -- 614
        sprites.playerSheet:getHeight() / 3, -- 564
        sprites.playerSheet:getWidth(),
        sprites.playerSheet:getHeight()
    );
    -- enemy is 200x79px
    -- so each sprite will be 100x79
    local enemyGrid = anim8.newGrid(
        sprites.enemySheet:getWidth() / 2, 79,
        sprites.enemySheet:getWidth(),
        sprites.enemySheet:getHeight()
    );

    animations = {}
    -- 1-15 -> the first 15 images from the sprite
    -- 1 -> first row
    -- 0.1 -> time between frames: 1/10 s
    animations.idle = anim8.newAnimation(grid('1-15', 1), 0.05);
    animations.jump = anim8.newAnimation(grid('1-7', 2), 0.05);
    animations.run = anim8.newAnimation(grid('1-15', 3), 0.05);

    -- enemy animations
    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), 0.03);

    wf = require 'libraries.windfield.windfield';
    world = wf.newWorld(0, 800, false); -- false - sleep

    world:setQueryDebugDrawing(true);
    world:addCollisionClass('Platform');
    world:addCollisionClass('Player');
    world:addCollisionClass('Danger');

    require('player');
    require('enemy');
    require('libraries.show');

    -- the danger zone collider
    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, { collision_class = 'Danger' }); -- adjust as necessary
    dangerZone:setType('static');

    platforms = {};

    flagX = 0;
    flagY = 0;

    saveData = {};
    saveData.currentLevel = 'level1';

    -- load the level from the file
    loadSavedLevel();

    -- load the correct map
    loadMap(saveData.currentLevel);
end

function love.update(dt)
    -- uncomment this to see the colliders
    -- world:update(dt);
    gameMap:update(dt);
    playerUpdate(dt);
    enemiesUpdate(dt);

    local px, py = player:getPosition();
    cam:lookAt(px, love.graphics.getHeight() / 2);

    levelChange();
end

function love.draw()
    -- NOTE: HUD stays outside the cam
    -- HUD settings goes gere
    love.graphics.draw(sprites.background, 0, 0);
    -- HUD settings ends here

    cam:attach()
    gameMap:drawLayer(gameMap.layers['Tile Layer 1']); -- the name from Tiled
    world:draw();
    playerDraw();
    enemiesDraw();
    cam:detach();
end

function love.keypressed(key)
    if (key == 'space') then
        if (player.grounded) then
            player:applyLinearImpulse(0, -4500);
            sounds.jump:play();
            sounds.jump:setVolume(0.5);
        end
    end
end

function spawnPlatform(x, y, width, height)
    if (width > 0 and height > 0) then
        -- the platform collider
        local platform = world:newRectangleCollider(x, y, width, height, { collision_class = 'Platform' });
        platform:setType('static');

        table.insert(platforms, platform);
    end
end

function destroy(obj)
    local i = #obj
    while i > -1 do
        if (obj[i] ~= nil) then
            obj[i]:destroy();
        end

        table.remove(obj, i);
        i = i - 1;
    end
end

function destroyAll()
    destroy(platforms);
    destroy(enemies)
end

function loadMap(mapName)
    -- save the data (levels, collectibles, lives etc)
    -- serialive the data - take the table content and put it in a file
    saveData.currentLevel = mapName;
    love.filesystem.write('savedData.lua', table.show(saveData, 'saveData'));

    -- destroy old elements when loading a new map
    destroyAll();

    -- load the map
    gameMap = sti('maps/' .. mapName .. '.lua');

    for i, obj in pairs(gameMap.layers['StartPos'].objects) do
        playerStartX = obj.x;
        playerStartY = obj.y;
    end

    -- set player start position
    player:setPosition(playerStartX, playerStartY);

    -- don't forget to add objects around each platform in Tiled
    -- 'Platforms' is the Object name from Tiled
    -- on mac the data is saved on /Users/username/Library/Application\ Support/LOVE
    for i, obj in pairs(gameMap.layers['Platforms'].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height); -- properties from Tiled when an object is selected
    end

    -- add a square obj on each platform to match the enemy
    for i, obj in pairs(gameMap.layers['Enemies'].objects) do
        spawnEnemy(obj.x, obj.y);
    end

    for i, obj in pairs(gameMap.layers['Flag'].objects) do
        flagX = obj.x;
        flagY = obj.y;
    end
end

function levelChange()
    -- check the player is near the flag
    local colliders = world:queryCircleArea(flagX, flagY, 10, { 'Player' });
    if (#colliders > 0) then
        if (saveData.currentLevel == 'level1') then
            loadMap('level2');
        elseif (saveData.currentLevel == 'level2') then
            loadMap('level1');
        end
    end
end

function loadSavedLevel()
    if (love.filesystem.getInfo('savedData.lua')) then
        local data = love.filesystem.load('savedData.lua');
        -- this declaration is going to put the info it finds into the corresponding tables
        data();
    end
end
