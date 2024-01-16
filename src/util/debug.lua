function debug(input, separator)
    if mod.conf.debug == false then return end

    separator = separator or false

    log(mod.conf.log_prefix .. serpent.block(input, mod.conf.log_format))

    if separator == true then
        log(mod.conf.log_prefix .. "----------------------")
    end
end