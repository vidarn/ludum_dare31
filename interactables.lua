-- A file containing the functions to call when an object is being interacted with.
return {
    ball = {
        create = function(id)
            set_sprite(id,"objects.png",1,1,0.2,1,32,32,-16,-24)
        end,
        
        interact = function(id)
            print("ball interact!" .. id)
            set_sprite(id,"objects.png",2,1,0.2,1,32,32,-16,-24)
        end
    },

    tree = {
        create = function(id)
            set_sprite(id,"tree.png",1,1,0.2,1,162,162,-162/2,-162+20)
        end,
        interact = function(id)
        end
    }

}
