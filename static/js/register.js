Vue.http.get( cntlr + "tool/register_data" ).then( function (response) {
    var data = response.body;

    var vm = new Vue({
        el      : "#register",
        data    : data,
        methods : {
            reorder : function ( direction, person_index, team_index ) {
                if ( team_index > -1 ) {
                    var element = this.teams[team_index].splice( person_index, 1 )[0];

                    if ( direction == -1 ) {
                        if ( person_index != 0 ) {
                            this.teams[team_index].splice( person_index - 1, 0, element );
                        }
                        else {
                            var target = team_index - 1;
                            if ( target < 0 ) target = this.teams.length - 1;
                            this.teams[target].push(element);
                        }
                    }
                    else if ( direction == 1 ) {
                        if ( person_index != this.teams[team_index].length ) {
                            this.teams[team_index].splice( person_index + 1, 0, element );
                        }
                        else {
                            var target = team_index + 1;
                            if ( target > this.teams.length - 1 ) target = 0;
                            this.teams[target].unshift(element);
                        }
                    }
                }
                else {
                    var element = this.non_quizzers.splice( person_index, 1 )[0];

                    if ( direction == -1 ) {
                        if ( person_index != 0 ) {
                            this.non_quizzers.splice( person_index - 1, 0, element );
                        }
                        else {
                            this.non_quizzers.push(element);
                        }
                    }
                    else if ( direction == 1 ) {
                        if ( person_index != this.non_quizzers.length ) {
                            this.non_quizzers.splice( person_index + 1, 0, element );
                        }
                        else {
                            this.non_quizzers.unshift(element);
                        }
                    }
                }
            },

            delete_person : function ( person_index, team_index ) {
                if ( team_index > -1 ) {
                    this.teams[team_index].splice( person_index, 1 );
                    if ( this.teams[team_index].length == 0 ) this.teams.splice( team_index, 1 );
                }
                else {
                    this.non_quizzers.splice( person_index, 1 );
                }

                this.$nextTick( function () {
                    nav_content_align.align();
                } );
            },

            add_team : function () {
                this.teams.push([{ attend : true, house : true, lunch : true }]);

                this.$nextTick( function () {
                    nav_content_align.align();
                } );
            },

            add_quizzer : function (team) {
                team.push({ attend : true, house : true, lunch : true });

                this.$nextTick( function () {
                    nav_content_align.align();
                } );
            },

            add_non_quizzer : function () {
                this.non_quizzers.push({ attend : true, house : true, lunch : true });

                this.$nextTick( function () {
                    nav_content_align.align();
                } );
            },

            save_registration : function () {
                var register     = document.createElement("form");
                register.action  = cntlr + "tool/register";
                register.method  = "post";
                register.enctype = "multipart/form-data";

                var register_input   = document.createElement("input");
                register_input.name  = "data";
                register_input.value = JSON.stringify(data);

                register.appendChild(register_input);
                document.body.appendChild(register);

                register.submit();
            }
        },

        mounted : function () {
            nav_content_align.align();
        }
    });

    for ( var t = 0; t < data.teams.length; t++ ) {
        for ( var q = 0; q < data.teams[t].length; q++ ) {
            vm.$watch(
                "teams." + t + "." + q + ".attend",
                ( function () {
                    var _t = t;
                    var _q = q;

                    return function (attend) {
                        if ( attend == null ) return;
                        this.teams[_t][_q].house = attend;
                        this.teams[_t][_q].lunch = attend;
                    }
                } )()
            );
        }
    }

    for ( var n = 0; n < data.non_quizzers.length; n++ ) {
        vm.$watch(
            "non_quizzers." + n + ".attend",
            ( function () {
                var _n = n;

                return function (attend) {
                    if ( attend == null ) return;
                    this.non_quizzers[_n].house = attend;
                    this.non_quizzers[_n].lunch = attend;
                }
            } )()
        );
    }
});
