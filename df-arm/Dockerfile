FROM p6steve/rakudo:notebook-arm64-2021.05
    
RUN zef install -v Math::Polygons \ 
    && git clone https://github.com/p6steve/raku-Math-Polygons.git \
    && cp -R raku-Math-Polygons/eg / \
    && zef install -v Physics::Measure Physics::Constants \
    && zef install -v https://github.com/p6steve/raku-Physics-Navigation.git \
    && git clone https://github.com/p6steve/raku-Yacht-Navigation.git \
    && cp -R raku-Yacht-Navigation/eg /

ENTRYPOINT ["/bin/bash"]

EXPOSE 8888

#CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
