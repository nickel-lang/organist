{
  nickel-nix = {
    builders = import "/nix/store/qb3qvz3xxvnwy5ma1b60ba2gw8pw9vas-5626jyxg49xsax707lciippzazpldgjn-source/builders.ncl",
    contracts = import "/nix/store/qb3qvz3xxvnwy5ma1b60ba2gw8pw9vas-5626jyxg49xsax707lciippzazpldgjn-source/contracts.ncl",
    naked-stdenv = import "/nix/store/qb3qvz3xxvnwy5ma1b60ba2gw8pw9vas-5626jyxg49xsax707lciippzazpldgjn-source/naked-stdenv.ncl",
    nix = import "/nix/store/qb3qvz3xxvnwy5ma1b60ba2gw8pw9vas-5626jyxg49xsax707lciippzazpldgjn-source/nix.ncl",
  },
}
