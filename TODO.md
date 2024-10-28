## Todo list for multus thick plugin
- [X] check multus init containers compared to upstream manifest
    - the thick plugin init container should be the same image as the thick plugin with command:
    https://github.com/k8snetworkplumbingwg/multus-cni/blob/e1a0d2a3fd4f490861ff1872840fdf0a69200747/deployments/multus-daemonset-thick.yml#L200
- [ ] add option to mount CNI delegate config dir
- [ ] check: do we need thin plugin init container as well?
