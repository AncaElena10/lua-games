playerStartX = 0;
playerStartY = 0;

-- the player collider
-- adjust as necessary
local playerColliderWidth = 40;
local playerColliderHeight = 100;

player = world:newRectangleCollider(
    playerStartX, playerStartY,
    playerColliderWidth, playerColliderHeight,
    { collision_class = 'Player' }
);
player:setFixedRotation(true);
player.speed = 260;
player.animation = animations.idle;
player.isMoving = false;
player.direction = 1;   -- 1 facing right, -1 facing left
player.grounded = true; -- using this for jump anim

function playerUpdate(dt)
    if (player.body) then -- only if the player still exists (did not hit the danger zone for ex)
        local colliders = world:queryRectangleArea(
            player:getX() - playerColliderWidth / 2,
            player:getY() + playerColliderHeight / 2,
            playerColliderWidth, 2,
            { 'Platform' }
        );
        -- if there are no platforms, it means that the player is in the air
        if (#colliders > 0) then -- number of colliders > 0
            player.grounded = true;
        else
            player.grounded = false;
        end

        player.isMoving = false;

        local px, py = player:getPosition();
        if (love.keyboard.isDown('d')) then
            player:setX(px + player.speed * dt);

            player.isMoving = true;
            player.direction = 1;
        end
        if (love.keyboard.isDown('a')) then
            player:setX(px - player.speed * dt);

            player.isMoving = true;
            player.direction = -1;
        end

        if (player:enter('Danger')) then
            player:setPosition(playerStartX, playerStartY);
        end
    end

    if (player.grounded) then
        if (player.isMoving) then
            player.animation = animations.run;
        else
            player.animation = animations.idle;
        end
    else
        player.animation = animations.jump;
    end

    player.animation:update(dt);
end

function playerDraw()
    local px, py = player:getPosition();
    player.animation:draw(
        sprites.playerSheet,
        px, py,
        nil,
        0.25 * player.direction, -- scale factor - if multiplied by -1, it will change the facing
        0.25,
        130,                     -- aprox value
        300                      -- aprox value
    );
end
