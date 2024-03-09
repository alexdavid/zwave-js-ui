# Nix Z-Wave JS UI

This is a fork of [`zwave-js-ui`](https://github.com/zwave-js/zwave-js-ui) that
I have nixified for deployment in my infrastructure.

Attempting to nixify it with `npmlock2nix` results in issues because
`zwave-js-ui` depends on [`pinia`](https://www.npmjs.com/package/pinia), which
depends on [`vue-demi`](https://www.npmjs.com/package/vue-demi). `vue-demi`
seems to do some [crazy post-install
shenanigans](https://github.com/vueuse/vue-demi/blob/main/package.json#L35) to
actually template out the `node_modules` directory which does not play well
with `npmlock2nix`.

After banging my head against the wall on this problem for a few hours I
decided it would just be simpler to vendor `node_modules` and write a flake
file around that.

Related:
https://github.com/NixOS/nixpkgs/issues/230686

## Usage

Via a systemd unit:
```nix
systemd.user.services.zwave-js-ui = {
  enable = true;
  serviceConfig = {
    Type = "simple";
    ExecStart = ''
      ${pkgs.lib.meta.getExe ${zwave-js-ui-flake-input}.packages.${system}.default} /path/to/store;
    '';
  };
};
```

## Jail

This flake currently runs zwave-js-ui in a bubblewrap jail. This is done for
two reasons:

1. It was a trivial way to bind-mount a `store` directory which zwave-js-ui
   expects to be within the source directory. This way the nodejs source can
   stay in `/nix/store` and a `store` that zwave-js-ui writes to can be any
2. I personally do not like to run anything from npm outside of a sandbox given
   its track record of supply-chain attacks.

I have not yet tested running this with a usb zwave controller yet. The call to
`bwrap` will likely need to change.
